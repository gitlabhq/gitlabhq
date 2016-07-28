module Gitlab
  class GitPostReceive
    include Gitlab::Identifier
    attr_reader :repo_path, :identifier, :changes, :project

    def initialize(repo_path, identifier, changes)
      repo_path.gsub!(/\.git\z/, '')
      repo_path.gsub!(/\A\//, '')

      @repo_path = repo_path
      @identifier = identifier
      @changes = deserialize_changes(changes)

      retrieve_project_and_type
    end

    def wiki?
      @type == :wiki
    end

    def regular_project?
      @type == :project
    end

    def identify(revision)
      super(identifier, project, revision)
    end

    private

    def retrieve_project_and_type
      @type = :project
      @project = Project.find_with_namespace(@repo_path)

      if @repo_path.end_with?('.wiki') && !@project
        @type = :wiki
        @project = Project.find_with_namespace(@repo_path.gsub(/\.wiki\z/, ''))
      end
    end

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
