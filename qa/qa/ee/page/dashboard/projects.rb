module QA
  module EE
    module Page
      module Dashboard
        module Projects
          def wait_for_project_replication(project_name)
            wait(max: Runtime::Geo.max_db_replication_time) do
              filter_by_name(project_name)

              page.has_text?(project_name)
            end
          end
        end
      end
    end
  end
end
