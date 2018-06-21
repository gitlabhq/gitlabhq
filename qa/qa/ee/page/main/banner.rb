module QA
  module EE
    module Page
      module Main
        class Banner < QA::Page::Base
          view 'ee/app/helpers/ee/application_helper.rb' do
            element :read_only_message, 'You are on a secondary, <b>read-only</b> Geo node.'
          end

          def has_secondary_read_only_banner?
            page.has_text?('You are on a secondary, read-only Geo node.')
          end
        end
      end
    end
  end
end
