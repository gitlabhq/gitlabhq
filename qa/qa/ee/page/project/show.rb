module QA
  module EE
    module Page
      module Project
        module Show
          def wait_for_repository_replication
            wait(max: Runtime::Geo.max_file_replication_time) do
              !page.has_text?(/No repository|The repository for this project is empty/)
            end
          end
        end
      end
    end
  end
end
