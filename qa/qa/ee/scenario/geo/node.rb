module QA
  module EE
    module Scenario
      module Geo
        class Node < QA::Scenario::Template
          attr_accessor :address

          def perform
            QA::Page::Main::Entry.act { visit_login_page }
            QA::Page::Main::Login.act { sign_in_using_credentials }
            QA::Page::Main::Menu.act { go_to_admin_area }
            QA::Page::Admin::Menu.act { go_to_geo_nodes }
            EE::Page::Admin::Geo::Nodes::Show.act { new_node! }

            EE::Page::Admin::Geo::Nodes::New.perform do |page|
              raise ArgumentError if @address.nil?

              page.set_node_address(@address)
              page.add_node!
            end

            QA::Page::Main::Menu.act { sign_out }
          end
        end
      end
    end
  end
end
