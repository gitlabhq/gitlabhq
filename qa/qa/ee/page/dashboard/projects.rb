module QA
  module EE
    module Page
      module Dashboard
        module Projects
          def wait_for_project_replication(project_name)
            wait(max: 180) do
              filter_by_name(project_name)

              page.has_content?(project_name)
            end
          end
        end
      end
    end
  end
end
