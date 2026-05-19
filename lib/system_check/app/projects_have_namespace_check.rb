# frozen_string_literal: true

module SystemCheck
  module App
    class ProjectsHaveNamespaceCheck < SystemCheck::BaseCheck
      set_name 'Projects have namespace:'
      set_skip_reason "can't check, you have no projects"

      def skip?
        !Project.exists?
      end

      def multi_check
        say ''

        Project.find_each(batch_size: 100) do |project|
          print sanitized_message(project) # rubocop:disable Rails/Output -- system check CLI output

          if project.namespace
            say Rainbow('yes').green
          else
            say Rainbow('no').red
            show_error
          end
        end
      end

      def show_error
        try_fixing_it(
          "Migrate global projects"
        )
        for_more_information(
          "doc/update/5.4-to-6.0.md in section \"#global-projects\""
        )
        fix_and_rerun
      end
    end
  end
end
