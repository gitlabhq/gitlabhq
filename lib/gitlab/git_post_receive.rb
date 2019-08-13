# frozen_string_literal: true

module Gitlab
  class GitPostReceive
    include Gitlab::Identifier
    attr_reader :project, :identifier, :changes, :push_options

    def initialize(project, identifier, changes, push_options = {})
      @project = project
      @identifier = identifier
      @changes = deserialize_changes(changes)
      @push_options = push_options
    end

    def identify
      super(identifier)
    end

    def changes_refs
      return changes unless block_given?

      changes.each do |change|
        change.strip!
        oldrev, newrev, ref = change.split(' ')

        yield oldrev, newrev, ref
      end
    end

    def includes_branches?
      enum_for(:changes_refs).any? do |_oldrev, _newrev, ref|
        Gitlab::Git.branch_ref?(ref)
      end
    end

    def includes_tags?
      enum_for(:changes_refs).any? do |_oldrev, _newrev, ref|
        Gitlab::Git.tag_ref?(ref)
      end
    end

    private

    def deserialize_changes(changes)
      utf8_encode_changes(changes).each_line
    end

    def utf8_encode_changes(changes)
      changes.force_encoding('UTF-8')
      return changes if changes.valid_encoding?

      # Convert non-UTF-8 branch/tag names to UTF-8 so they can be dumped as JSON.
      detection = CharlockHolmes::EncodingDetector.detect(changes)
      return changes unless detection && detection[:encoding]

      CharlockHolmes::Converter.convert(changes, detection[:encoding], 'UTF-8')
    end
  end
end
