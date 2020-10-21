# frozen_string_literal: true

module QA
  module Resource
    module Events
      module Project
        include Events::Base

        def wait_for_merge(title)
          QA::Runtime::Logger.debug(%Q[#{self.class.name} - wait_for_merge with title "#{title}"])
          wait_for_event do
            events(action: 'accepted', target_type: 'merge_request').any? { |event| event[:target_title] == title }
          end
        end

        def wait_for_push(commit_message)
          QA::Runtime::Logger.debug(%Q[#{self.class.name} - wait_for_push with commit message "#{commit_message}"])
          wait_for_event do
            events(action: 'pushed').any? { |event| event.dig(:push_data, :commit_title) == commit_message }
          end
        end

        def wait_for_push_new_branch(branch_name = "master")
          QA::Runtime::Logger.debug(%Q[#{self.class.name} - wait_for_push_new_branch with branch_name "#{branch_name}"])
          wait_for_event do
            events(action: 'pushed').any? { |event| event.dig(:push_data, :ref) == branch_name }
          end
        end
      end
    end
  end
end
