module Gitlab
  class GitPostReceive
    include Gitlab::Identifier

    UTF8_ENCODING = 'UTF-8'.freeze

    attr_reader :project, :identifier, :changes

    def initialize(project, identifier, changes)
      @project = project
      @identifier = identifier
      @changes = deserialize_changes(changes)
    end

    def identify(revision)
      super(identifier, project, revision)
    end

    def changes_refs
      return changes unless block_given?

      changes.each do |change|
        change.strip!
        oldrev, newrev, ref = change.split(' ')

        yield oldrev, newrev, ref
      end
    end

    private

    def deserialize_changes(changes)
      utf8_encode_changes(changes).each_line
    end

    def utf8_encode_changes(changes)
      changes.force_encoding(UTF8_ENCODING)
      return changes if changes.valid_encoding?

      # Convert non-UTF-8 branch/tag names to UTF-8 so they can be dumped as JSON.
      detection = CharlockHolmes::EncodingDetector.detect(changes)
      return changes unless detection && detection[:encoding]

      CharlockHolmes::Converter.convert(changes, detection[:encoding], UTF8_ENCODING)
    end
  end
end
