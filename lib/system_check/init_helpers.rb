# frozen_string_literal: true

require 'open3'

module SystemCheck
  module InitHelpers
    # Return the Wants= of a unit, empty if the unit doesn't exist
    def systemd_get_wants(unitname)
      stdout, _stderr, status = Open3.capture3("systemctl", "--no-pager", "show", unitname)

      unless status
        return []
      end

      wantsline = stdout.lines.find { |line| line.start_with?("Wants=") }

      unless wantsline
        return []
      end

      wantsline.delete_prefix("Wants=").strip.split
    end
  end
end
