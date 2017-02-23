module Gitlab
  module Git
    class Index
      DEFAULT_MODE = 0o100644

      attr_reader :repository, :raw_index

      def initialize(repository)
        @repository = repository
        @raw_index = repository.rugged.index
      end

      delegate :read_tree, to: :raw_index

      def write_tree
        raw_index.write_tree(repository.rugged)
      end

      def get(*args)
        raw_index.get(*args)
      end

      def create(options)
        normalize_options!(options)

        file_entry = raw_index.get(options[:file_path])
        if file_entry
          raise Gitlab::Git::Repository::InvalidBlobName.new("Filename already exists")
        end

        add_blob(options)
      end

      def create_dir(options)
        normalize_options!(options)

        file_entry = raw_index.get(options[:file_path])
        if file_entry
          raise Gitlab::Git::Repository::InvalidBlobName.new("Directory already exists as a file")
        end

        options = options.dup
        options[:file_path] += '/.gitkeep'
        options[:content] = ''

        add_blob(options)
      end

      def update(options)
        normalize_options!(options)

        file_entry = raw_index.get(options[:file_path])
        unless file_entry
          raise Gitlab::Git::Repository::InvalidBlobName.new("File doesn't exist")
        end

        add_blob(options, mode: file_entry[:mode])
      end

      def move(options)
        normalize_options!(options)

        file_entry = raw_index.get(options[:previous_path])
        unless file_entry
          raise Gitlab::Git::Repository::InvalidBlobName.new("File doesn't exist")
        end

        raw_index.remove(options[:previous_path])

        add_blob(options, mode: file_entry[:mode])
      end

      def delete(options)
        normalize_options!(options)

        file_entry = raw_index.get(options[:file_path])
        unless file_entry
          raise Gitlab::Git::Repository::InvalidBlobName.new("File doesn't exist")
        end

        raw_index.remove(options[:file_path])
      end

      private

      def normalize_options!(options)
        options[:file_path] = normalize_path(options[:file_path]) if options[:file_path]
        options[:previous_path] = normalize_path(options[:previous_path]) if options[:previous_path]
      end

      def normalize_path(path)
        pathname = Gitlab::Git::PathHelper.normalize_path(path)

        if pathname.each_filename.include?('..')
          raise Gitlab::Git::Repository::InvalidBlobName.new('Invalid path')
        end

        pathname.to_s
      end

      def add_blob(options, mode: nil)
        content = options[:content]
        return unless content

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
        raise Gitlab::Git::Repository::InvalidBlobName.new(e.message)
      end
    end
  end
end
