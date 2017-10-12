module QA
  module EE
    module Page
      module Admin
        class License < QA::Page::Base
          def no_license?
            page.has_content?('You do not have a license')
          end

          def add_new_license(key)
            raise 'License key empty!' if key.to_s.empty?

            click_link 'Upload New License'
            choose 'Enter license key'
            fill_in 'License key', with: key
            click_button 'Upload license'
          end
        end
      end
    end
  end
end
