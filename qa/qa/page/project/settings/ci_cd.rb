module QA
  module Page
    module Project
      module Settings
        class CICD < Page::Base
          include Common

          view 'app/views/projects/settings/ci_cd/show.html.haml' do
            element :runners_settings, 'Runners settings'
          end

          def expand_runners_settings(&block)
            expand_section('Runners settings') do
              Settings::Runners.perform(&block)
            end
          end
        end
      end
    end
  end
end
