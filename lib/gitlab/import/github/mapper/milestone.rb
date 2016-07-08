module Gitlab
  module Import
    module Github
      module Mapper
        class Milestone < Base
          private

          def attributes_for(raw)
            {
              iid: raw.number,
              project: project,
              title: raw.title,
              description: raw.description,
              due_date: raw.due_on,
              state: raw.state == 'closed' ? 'closed' : 'active',
              created_at: raw.created_at,
              updated_at: raw.state == 'closed' ? raw.closed_at : raw.updated_at
            }
          end

          def klass
            ::Milestone
          end
        end
      end
    end
  end
end
