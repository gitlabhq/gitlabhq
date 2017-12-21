module QA
  module Page
    module Project
      module Settings
        class DeployKey < Repository
          def initialize
            super

            expand('Deploy Keys')
          end

          def fill_new_deploy_key_title(title)
            fill_in 'deploy_key_title', with: title
          end

          def fill_new_deploy_key_key(key)
            fill_in 'deploy_key_key', with: key
          end

          def add_key
            click_on 'Add key'
          end

          def has_key_title?(title)
            page.within('.deploy-keys') do
              page.find('.title', text: title)
            end
          end
        end
      end
    end
  end
end
