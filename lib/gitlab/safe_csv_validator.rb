# frozen_string_literal: true

module Gitlab
  # Quickly validates a CSV string. Use it as a guard *before* parsing the CSV
  # to ensure safe memory usage.
  #
  # Each limit is a separate concern:
  #
  # * `max_size`            - the file is too big in bytes.
  # * `max_rows`            - the file has too many lines.
  # * `max_header_columns`  - the first line has too many columns, which
  #                           matters because `CSV.parse(..., header_converters: :symbol)`
  #                           allocates one Ruby symbol per header.
  # * `max_delimiters`      - the file has too many separator characters
  #                           overall, catching CSVs that pack a huge number
  #                           of fields without tripping the row or column
  #                           limits individually.
  #
  # The validator never parses the CSV itself - it only counts bytes and
  # characters, which is cheap and bounded. If any limit is exceeded it
  # raises a specific `LimitExceededError` subclass; otherwise it returns
  # `nil` and the caller is free to invoke a real parser.
  #
  # @example Use the conservative defaults
  #   Gitlab::SafeCsvValidator.new.validate!(raw_csv)
  #
  # @example Override a single limit, accept the rest
  #   Gitlab::SafeCsvValidator.new(max_rows: 1_000).validate!(raw_csv)
  #
  # @example Disable one specific check
  #   Gitlab::SafeCsvValidator.new(max_size: nil).validate!(raw_csv)
  class SafeCsvValidator # rubocop:disable Gitlab/NamespacedClass -- Generic CSV safety utility, no product domain
    LimitExceededError = Class.new(StandardError)
    SizeLimitError = Class.new(LimitExceededError)
    DelimiterLimitError = Class.new(LimitExceededError)
    HeaderColumnLimitError = Class.new(LimitExceededError)
    RowLimitError = Class.new(LimitExceededError)

    # Defaults cover the common delimiter set used by CSV variants:
    # `,` (RFC 4180), `;` (European), `\t` (TSV), and `\n`/`\r` row
    # terminators. Header check excludes row terminators since columns
    # are counted on a single line.
    DEFAULT_DELIMITER_CHARS = ",;\t\n\r"
    DEFAULT_HEADER_DELIMITER_CHARS = ",;\t"

    # Conservative defaults that bound the cost of parsing untrusted CSV.
    # Callers can override any individual limit, or pass `nil` to disable
    # a specific check.
    DEFAULTS = {
      max_size: 10.megabytes,
      max_delimiters: 250_000,
      max_header_columns: 100,
      max_rows: 20_000,
      delimiter_chars: DEFAULT_DELIMITER_CHARS,
      header_delimiter_chars: DEFAULT_HEADER_DELIMITER_CHARS
    }.freeze

    attr_reader :options

    # @param options [Hash] caller-provided overrides; merged on top of DEFAULTS
    # @option options [Integer] :max_size            Maximum body size in bytes
    # @option options [Integer] :max_delimiters      Maximum total count of delimiter characters across the file
    # @option options [Integer] :max_header_columns  Maximum column count on the first (header) line
    # @option options [Integer] :max_rows            Maximum number of rows, approximated by counting newlines
    # @option options [String]  :delimiter_chars        Character set counted toward :max_delimiters
    # @option options [String]  :header_delimiter_chars Character set counted toward :max_header_columns
    def initialize(options = {})
      @options = DEFAULTS.merge(options)
    end

    # Runs every configured check against the raw CSV body. Each limit is
    # optional; omitting an option disables the corresponding check.
    #
    # @param raw_csv [String]
    # @return [nil]
    # @raise [LimitExceededError] when a configured limit is exceeded
    def validate!(raw_csv)
      return if raw_csv.nil? || raw_csv.empty?

      check_size!(raw_csv)
      check_delimiters!(raw_csv)
      check_rows!(raw_csv)
      check_header_columns!(raw_csv)
    end

    private

    def check_size!(raw_csv)
      max = options[:max_size]
      return unless max
      return if raw_csv.bytesize <= max

      raise SizeLimitError,
        "CSV body size #{raw_csv.bytesize} exceeds limit of #{max}"
    end

    def check_delimiters!(raw_csv)
      max = options[:max_delimiters]
      return unless max
      return if raw_csv.count(options[:delimiter_chars]) <= max

      raise DelimiterLimitError,
        "CSV delimiter count exceeds limit of #{max}"
    end

    # Approximates row count by counting newline characters. Over-counts when
    # fields contain literal newlines inside quoted values, which is conservative
    # for a safety bound (callers needing exact row counts should also check after parsing).
    def check_rows!(raw_csv)
      max = options[:max_rows]
      return unless max
      return if raw_csv.count("\n") <= max

      raise RowLimitError,
        "CSV row count exceeds limit of #{max}"
    end

    def check_header_columns!(raw_csv)
      max = options[:max_header_columns]
      return unless max

      header_line = raw_csv.each_line.first || ''
      return if header_line.count(options[:header_delimiter_chars]) < max

      raise HeaderColumnLimitError,
        "CSV header column count exceeds limit of #{max}"
    end
  end
end
