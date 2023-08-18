# frozen_string_literal: true

module QA
  RSpec.shared_examples 'workspaces actions' do
    it 'creates a new workspace and then stops and terminates it' do
      QA::Page::Main::Menu.perform(&:go_to_workspaces)
      workspace_name = ""

      QA::EE::Page::Workspace::List.perform do |list|
        existing_workspaces = list.get_workspaces_list
        list.create_workspace(kubernetes_agent.name, devfile_project.name)
        updated_workspaces = list.get_workspaces_list
        workspace_name = (updated_workspaces - existing_workspaces).fetch(0, '').to_s
        raise "Workspace name is empty" if workspace_name == ''

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
        expect(list_item).to have_workspace_state(workspace_name, "Terminated")
      end
    end
  end
end
