module Gitlab
  module Import
    module Action
      class ImportLabels
        def initialize(project, client)
          @mapper = Github::Mapper::Label.new(project, client)
        end

        def execute
          mapper.each(&:save)
        end

        private

        attr_reader :mapper
      end
    end
  end
end
