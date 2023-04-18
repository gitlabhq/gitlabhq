# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Sidebar
        module Overview
          def go_to_users_overview
            open_overview_submenu("Users")
          end

          def go_to_groups_overview
            open_overview_submenu("Groups")
          end

          private

          def open_overview_submenu(sub_menu)
            open_submenu("Overview", sub_menu)
          end
        end
      end
    end
  end
end
