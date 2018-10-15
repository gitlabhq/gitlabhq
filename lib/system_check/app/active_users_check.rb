# frozen_string_literal: true

module SystemCheck
  module App
    class ActiveUsersCheck < SystemCheck::BaseCheck
      set_name 'Active users:'

      def multi_check
        active_users = User.active.count

        if active_users > 0
          $stdout.puts active_users.to_s.color(:green)
        else
          $stdout.puts active_users.to_s.color(:red)
        end
      end
    end
  end
end
