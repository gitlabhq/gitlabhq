# frozen_string_literal: true

module SystemCheck
  module App
    class ActiveUsersCheck < SystemCheck::BaseCheck
      set_name 'Active users:'

      def multi_check
        active_users = User.active.count
        color_status = :red
        color_status = :green if active_users > 0
        $stdout.puts Rainbow(active_users.to_s).color(color_status)
      end
    end
  end
end
