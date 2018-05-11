module QA
  module EE
    module Page
      module Project
        module Show
          def wait_for_repository_replication
            wait(max: 180) do
              !page.has_content?('The repository for this project is empty')
            end
          end
        end
      end
    end
  end
end
