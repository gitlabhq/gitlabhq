# frozen_string_literal: true

module QA
  RSpec.shared_examples 'workspaces actions' do
    it 'creates a new workspace and then stops and terminates it' do
      QA::Page::Main::Menu.perform(&:go_to_homepage)
      QA::Page::Main::Menu.perform(&:go_to_workspaces)
      workspace_name = ""

      QA::EE::Page::Workspace::List.perform do |list|
        workspace_name = list.create_workspace(kubernetes_agent.name, devfile_project.name)

        expect(list).to have_workspace_state(workspace_name, "Creating")
        expect(list).to have_workspace_state(workspace_name, "Running")
      end

      QA::EE::Page::Workspace::Action.perform do |workspace|
        workspace.click_workspace_action(workspace_name, "stop")
      end

      QA::EE::Page::Workspace::List.perform do |list|
        expect(list).to have_workspace_state(workspace_name, "Stopped")
      end

      QA::EE::Page::Workspace::Action.perform do |workspace|
        workspace.click_workspace_action(workspace_name, "terminate")
      end

      QA::EE::Page::Workspace::List.perform do |list|
        # Check workspace not present on Active tab
        expect { list.get_workspaces_list }.not_to eventually_include(workspace_name).within(max_duration: 60)

        # Check workspace is present on Terminated tab
        list.click_terminated_tab
        expect(list).to have_workspace_state(workspace_name, "Terminated")
      end
    end
  end
end
