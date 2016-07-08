module Gitlab
  module Import
    module Github
      module Mapper
        class Label
          def initialize(project, client)
            @project = project
            @client  = client
          end

          def each
            return enum_for(:each) unless block_given?

            client.labels.each do |raw|
              label = ::Label.new(
                project: project,
                title: raw.name,
                color: "##{raw.color}"
              )

              yield(label)
            end
          end

          private

          attr_reader :project, :client
        end
      end
    end
  end
end
