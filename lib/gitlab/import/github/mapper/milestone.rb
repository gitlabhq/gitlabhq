module Gitlab
  module Import
    module Github
      module Mapper
        class Milestone
          def initialize(project, client)
            @project = project
            @client  = client
          end

          def each
            return enum_for(:each) unless block_given?

            client.milestones.each do |raw|
              milestone = ::Milestone.new(
                iid: raw.number,
                project: project,
                title: raw.title,
                description: raw.description,
                due_date: raw.due_on,
                state: raw.state == 'closed' ? 'closed' : 'active',
                created_at: raw.created_at,
                updated_at: raw.state == 'closed' ? raw.closed_at : raw.updated_at
              )

              yield(milestone)
            end
          end

          private

          attr_reader :project, :client
        end
      end
    end
  end
end
