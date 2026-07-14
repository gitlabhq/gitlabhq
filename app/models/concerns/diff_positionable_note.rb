# frozen_string_literal: true

module DiffPositionableNote
  extend ActiveSupport::Concern

  # Tokenizes a Ruby Hash#inspect string when recovering a malformed position
  # column. The alternatives are ordered so a complete double-quoted string
  # literal is matched before any structural token; a quoted value is therefore
  # consumed whole and left untouched, so `=>`, `nil`, or `:foo` appearing
  # inside a value (e.g. a path like `a=>b.rb`) is never rewritten.
  RUBY_HASH_INSPECT_TOKEN = /
    "(?:\\.|[^"\\])*"      # complete double-quoted string literal -> verbatim
    | :[A-Za-z_]\w*[!?]?   # Ruby symbol (e.g. :start) -> quoted JSON string
    | =>                   # hash rocket -> :
    | \bnil\b              # nil -> null
  /x

  included do
    before_validation :set_original_position, on: :create
    before_validation :update_position, on: :create, if: :should_update_position?, unless: :importing?

    serialize :original_position, type: Gitlab::Diff::Position # rubocop:disable Cop/ActiveRecordSerialize
    serialize :position, type: Gitlab::Diff::Position # rubocop:disable Cop/ActiveRecordSerialize
    serialize :change_position, type: Gitlab::Diff::Position # rubocop:disable Cop/ActiveRecordSerialize

    validate :diff_refs_match_commit, if: :for_commit?
    validates :position, json_schema: { filename: "position", hash_conversion: true }
  end

  %i[original_position position change_position].each do |meth|
    define_method "#{meth}=" do |new_position|
      if new_position.is_a?(String)
        new_position = begin
          Gitlab::Json.safe_parse(new_position)
        rescue StandardError
          nil
        end
      end

      if new_position.is_a?(Hash)
        new_position = new_position.with_indifferent_access
        new_position = Gitlab::Diff::Position.new(new_position)
      elsif !new_position.is_a?(Gitlab::Diff::Position)
        new_position = nil
      end

      return if new_position == read_attribute(meth)

      super(new_position)
    end

    define_method(meth) do
      super()
    rescue Psych::SyntaxError => e
      # A corrupt YAML column is read many times during a single request
      # (cache_key, active?, reply_attributes, serializers, ...). Dedupe the
      # Sentry event per (note, attribute) to avoid flooding ingest with
      # identical events.
      track_key = [:diff_positionable_note_yaml_error, id, meth]
      Gitlab::SafeRequestStore.fetch(track_key) do
        Gitlab::ErrorTracking.track_exception(
          e,
          note_id: id,
          noteable_type: read_attribute(:noteable_type),
          noteable_id: read_attribute(:noteable_id),
          attribute: meth
        )
        true
      end

      # Attempt to recover a stringified Ruby Hash stored as a raw string
      # (e.g. `{"base_sha"=>"abc..."}`) instead of YAML-serialized position.
      # The value is recovered on every read and never persisted here.
      recover_stringified_position(read_attribute_before_type_cast(meth), meth)
    end
  end

  # Returns true when +raw+ looks like a Ruby Hash#inspect string, with either
  # string keys (`{"key"=>"val"}`) or symbol keys (`{:key=>"val"}`), which
  # indicates a malformed position column. A correctly serialized position is
  # YAML and starts with `---`, so neither prefix yields a false positive.
  def stringified_hash?(raw)
    raw.is_a?(String) && raw.start_with?('{"', '{:')
  end

  # Attempts to parse a Ruby Hash#inspect string that was incorrectly stored
  # in a position column. Returns a Gitlab::Diff::Position on success, nil
  # otherwise.
  def recover_stringified_position(raw, meth = nil)
    return unless stringified_hash?(raw)

    # Convert Ruby hash-rocket syntax and Ruby-specific literals to valid JSON
    # so we can parse safely without resorting to eval. Transformations only
    # apply to structural tokens; values inside string literals are preserved
    # verbatim (see RUBY_HASH_INSPECT_TOKEN).
    json_str = raw.gsub(RUBY_HASH_INSPECT_TOKEN) do |token|
      case token
      when '=>' then ':'
      when 'nil' then 'null'
      when /\A"/ then token       # string literal, leave verbatim
      else %("#{token[1..]}")     # symbol -> "name"
      end
    end

    parsed = Gitlab::Json.safe_parse(json_str)
    return unless parsed.is_a?(Hash)

    Gitlab::Diff::Position.new(parsed.with_indifferent_access)
  rescue StandardError => e
    # Recovery hit an unexpected error (e.g. a shape the tokenizer could not
    # handle). The position is read many times per request, so dedupe the
    # Sentry event per note to avoid flooding ingest, then fall back to nil.
    track_key = [:diff_positionable_note_recovery_error, id, meth]
    Gitlab::SafeRequestStore.fetch(track_key) do
      Gitlab::ErrorTracking.track_exception(
        e,
        note_id: id,
        noteable_type: read_attribute(:noteable_type),
        noteable_id: read_attribute(:noteable_id),
        attribute: meth
      )
      true
    end

    nil
  end

  def should_update_position?
    on_text? || on_file?
  end

  def on_text?
    !!position&.on_text?
  end

  def on_file?
    !!position&.on_file?
  end

  def on_image?
    !!position&.on_image?
  end

  def supported?
    for_commit? || self.noteable.has_complete_diff_refs?
  end

  def active?(diff_refs = nil)
    return false unless supported?
    return true if for_commit?
    return false unless position

    diff_refs ||= noteable.diff_refs

    self.position.diff_refs == diff_refs
  end

  def set_original_position
    return unless position

    self.original_position = self.position.dup unless self.original_position&.complete?
  end

  def update_position
    return unless supported?
    return if for_commit?

    return if active?
    return unless position

    tracer = Gitlab::Diff::PositionTracer.new(
      project: self.project,
      old_diff_refs: self.position.diff_refs,
      new_diff_refs: self.noteable.diff_refs,
      paths: self.position.paths
    )

    result = tracer.trace(self.position)
    return unless result

    if result[:outdated]
      self.change_position = result[:position]
    else
      self.position = result[:position]
    end
  end

  def diff_refs_match_commit
    return if original_position && original_position.diff_refs == commit&.diff_refs

    errors.add(:commit_id, 'does not match the diff refs')
  end

  def enqueue_keep_around_commits
    MergeRequests::KeepAroundRefsWorker.perform_async(
      [project.id],
      shas,
      "#{noteable_type}/#{self.class.name}"
    )
  end

  def keep_around_commits
    repository.keep_around(*shas, source: "#{noteable_type}/#{self.class.name}")
  end

  def repository
    noteable.respond_to?(:repository) ? noteable.repository : project.repository
  end

  def shas
    return [] unless original_position

    [
      original_position.base_sha,
      original_position.start_sha,
      original_position.head_sha
    ].tap do |a|
      if position && position != original_position
        a << position.base_sha
        a << position.start_sha
        a << position.head_sha
      end
    end
  end
end
