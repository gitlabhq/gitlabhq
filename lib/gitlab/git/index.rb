# Gitaly note: JV: When the time comes I think we will want to copy this
# class into Gitaly. None of its methods look like they should be RPC's.
# The RPC's will be at a higher level.

module Gitlab
  module Git
    class Index
      IndexError = Class.new(StandardError)

      DEFAULT_MODE = 0o100644

      ACTIONS = %w(create create_dir update move delete).freeze
      ACTION_OPTIONS = %i(file_path previous_path content encoding).freeze

      attr_reader :repository, :raw_index

      def initialize(repository)
        @repository = repository
        @raw_index = repository.rugged.index
      end

      delegate :read_tree, :get, to: :raw_index

      def apply(action, options)
        validate_action!(action)
        public_send(action, options.slice(*ACTION_OPTIONS)) # rubocop:disable GitlabSecurity/PublicSend
      end

      def write_tree
        raw_index.write_tree(repository.rugged)
      end

      def dir_exists?(path)
        raw_index.find { |entry| entry[:path].start_with?("#{path}/") }
      end

      def create(options)
        options = normalize_options(options)

        if get(options[:file_path])
          raise IndexError, "A file with this name already exists"
        end

        add_blob(options)
      end

      def create_dir(options)
        options = normalize_options(options)

        if get(options[:file_path])
          raise IndexError, "A file with this name already exists"
        end

        if dir_exists?(options[:file_path])
          raise IndexError, "A directory with this name already exists"
        end

        options = options.dup
        options[:file_path] += '/.gitkeep'
        options[:content] = ''

        add_blob(options)
      end

      def update(options)
        options = normalize_options(options)

        file_entry = get(options[:file_path])
        unless file_entry
          raise IndexError, "A file with this name doesn't exist"
        end

        add_blob(options, mode: file_entry[:mode])
      end

      def move(options)
        options = normalize_options(options)

        file_entry = get(options[:previous_path])
        unless file_entry
          raise IndexError, "A file with this name doesn't exist"
        end

        if get(options[:file_path])
          raise IndexError, "A file with this name already exists"
        end

        raw_index.remove(options[:previous_path])

        add_blob(options, mode: file_entry[:mode])
      end

      def delete(options)
        options = normalize_options(options)

        unless get(options[:file_path])
          raise IndexError, "A file with this name doesn't exist"
        end

        raw_index.remove(options[:file_path])
      end

      private

      def normalize_options(options)
        options = options.dup
        options[:file_path] = normalize_path(options[:file_path]) if options[:file_path]
        options[:previous_path] = normalize_path(options[:previous_path]) if options[:previous_path]
        options
      end

      def normalize_path(path)
        unless path
          raise IndexError, "You must provide a file path"
        end

        pathname = Gitlab::Git::PathHelper.normalize_path(path.dup)

        pathname.each_filename do |segment|
          if segment == '..'
            raise IndexError, 'Path cannot include directory traversal'
          end
        end

        pathname.to_s
      end

      def add_blob(options, mode: nil)
        content = options[:content]
        unless content
          raise IndexError, "You must provide content"
        end

        content = Base64.decode64(content) if options[:encoding] == 'base64'

        detect = CharlockHolmes::EncodingDetector.new.detect(content)
        unless detect && detect[:type] == :binary
          # When writing to the repo directly as we are doing here,
          # the `core.autocrlf` config isn't taken into account.
          content.gsub!("\r\n", "\n") if repository.autocrlf
        end

        oid = repository.rugged.write(content, :blob)

        raw_index.add(path: options[:file_path], oid: oid, mode: mode || DEFAULT_MODE)
      rescue Rugged::IndexError => e
        raise IndexError, e.message
      end

      def validate_action!(action)
        unless ACTIONS.include?(action.to_s)
          raise ArgumentError, "Unknown action '#{action}'"
        end
      end
    end
  end
end
