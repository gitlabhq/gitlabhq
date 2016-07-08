module Gitlab
  module Import
    module Action
      class ImportLabels
        def initialize(project, client, result)
          @mapper = Github::Mapper::Label.new(project, client)
          @result = result
        end

        def execute
          mapper.each do |label|
            next if label.save

            label.errors.full_messages.each do |error|
              result.errors << "#{label.name}: #{error}"
            end
          end

          result
        end

        private

        attr_reader :mapper, :result
      end
    end
  end
end
