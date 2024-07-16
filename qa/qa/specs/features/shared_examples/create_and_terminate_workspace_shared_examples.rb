# frozen_string_literal: true

module QA
  RSpec.shared_examples 'workspaces actions' do
    it 'creates a new workspace and then stops and terminates it' do
      QA::Page::Main::Menu.perform(&:go_to_workspaces)
      workspace_name = ""

      QA::EE::Page::Workspace::List.perform do |list|
        workspace_name = list.create_workspace(kubernetes_agent.name, devfile_project.name)

        expect(list).to have_workspace_state(workspace_name, "Creating")
        list.wait_for_workspaces_creation(workspace_name)
        expect(list).to have_workspace_state(workspace_name, "Running")
      end

      QA::EE::Page::Workspace::Action.perform do |workspace|
        workspace.click_workspace_action(workspace_name, "stop")
      end

      QA::EE::Page::Workspace::List.perform do |list_item|
        expect(list_item).to have_workspace_state(workspace_name, "Stopped")
      end

      QA::EE::Page::Workspace::Action.perform do |workspace|
        workspace.click_workspace_action(workspace_name, "terminate")
      end

      QA::EE::Page::Workspace::List.perform do |list_item|
        list_item.click_terminated_tab
        expect(list_item).to have_workspace_state(workspace_name, "Terminated")
      end
    end
  end
end
