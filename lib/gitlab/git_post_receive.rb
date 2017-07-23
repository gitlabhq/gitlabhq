module Gitlab
  class GitPostReceive
    include Gitlab::Identifier
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
      return enum_for(:changes_refs) unless block_given?

      changes.each do |change|
        oldrev, newrev, ref = change.strip.split(' ')

        yield oldrev, newrev, ref
      end
    end

    private

    def deserialize_changes(changes)
      changes = utf8_encode_changes(changes)
      changes.lines
    end

    def utf8_encode_changes(changes)
      changes = changes.dup

      changes.force_encoding('UTF-8')
      return changes if changes.valid_encoding?

      # Convert non-UTF-8 branch/tag names to UTF-8 so they can be dumped as JSON.
      detection = CharlockHolmes::EncodingDetector.detect(changes)
      return changes unless detection && detection[:encoding]

      CharlockHolmes::Converter.convert(changes, detection[:encoding], 'UTF-8')
    end
  end
end
