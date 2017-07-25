require 'spec_helper'

describe 'Edit Project Settings', feature: true do
  let(:member) { create(:user) }
  let!(:project) { create(:project, :public, path: 'gitlab', name: 'sample') }
  let!(:issue) { create(:issue, project: project) }
  let(:non_member) { create(:user) }

  describe 'project features visibility selectors', js: true do
    before do
      project.team << [member, :master]
      sign_in(member)
    end

    tools = { builds: "pipelines", issues: "issues", wiki: "wiki", snippets: "snippets", merge_requests: "merge_requests" }

    tools.each do |tool_name, shortcut_name|
      describe "feature #{tool_name}" do
        it 'toggles visibility' do
          visit edit_project_path(project)

          select 'Disabled', from: "project_project_feature_attributes_#{tool_name}_access_level"
          click_button 'Save changes'
          wait_for_requests
          expect(page).not_to have_selector(".shortcuts-#{shortcut_name}")

          select 'Everyone with access', from: "project_project_feature_attributes_#{tool_name}_access_level"
          click_button 'Save changes'
          wait_for_requests
          expect(page).to have_selector(".shortcuts-#{shortcut_name}")

          select 'Only team members', from: "project_project_feature_attributes_#{tool_name}_access_level"
          click_button 'Save changes'
          wait_for_requests
          expect(page).to have_selector(".shortcuts-#{shortcut_name}")

          sleep 0.1
        end
      end
    end

    context 'When external issue tracker is enabled and issues enabled on project settings' do
      it 'does not hide issues tab' do
        allow_any_instance_of(Project).to receive(:external_issue_tracker).and_return(JiraService.new)

        visit project_path(project)

        expect(page).to have_selector('.shortcuts-issues')
      end
    end

    context 'When external issue tracker is enabled and issues disabled on project settings' do
      it 'hides issues tab' do
        project.issues_enabled = false
        project.save!
        allow_any_instance_of(Project).to receive(:external_issue_tracker).and_return(JiraService.new)

        visit project_path(project)

        expect(page).not_to have_selector('.shortcuts-issues')
      end
    end

    context "pipelines subtabs" do
      it "shows builds when enabled" do
        visit project_pipelines_path(project)

        expect(page).to have_selector(".shortcuts-builds")
      end

      it "hides builds when disabled" do
        allow(Ability).to receive(:allowed?).with(member, :read_builds, project).and_return(false)

        visit project_pipelines_path(project)

        expect(page).not_to have_selector(".shortcuts-builds")
      end
    end
  end

  describe 'project features visibility pages' do
    let(:pipeline) { create(:ci_empty_pipeline, project: project) }
    let(:job) { create(:ci_build, pipeline: pipeline) }

    let(:tools) do
      {
        builds: project_job_path(project, job),
        issues: project_issues_path(project),
        wiki: project_wiki_path(project, :home),
        snippets: project_snippets_path(project),
        merge_requests: project_merge_requests_path(project)
      }
    end

    context 'normal user' do
      before do
        sign_in(member)
      end

      it 'renders 200 if tool is enabled' do
        tools.each do |method_name, url|
          project.project_feature.update_attribute("#{method_name}_access_level", ProjectFeature::ENABLED)
          visit url
          expect(page.status_code).to eq(200)
        end
      end

      it 'renders 404 if feature is disabled' do
        tools.each do |method_name, url|
          project.project_feature.update_attribute("#{method_name}_access_level", ProjectFeature::DISABLED)
          visit url
          expect(page.status_code).to eq(404)
        end
      end

      it 'renders 404 if feature is enabled only for team members' do
        project.team.truncate

        tools.each do |method_name, url|
          project.project_feature.update_attribute("#{method_name}_access_level", ProjectFeature::PRIVATE)
          visit url
          expect(page.status_code).to eq(404)
        end
      end

      it 'renders 200 if user is member of group' do
        group = create(:group)
        project.group = group
        project.save

        group.add_owner(member)

        tools.each do |method_name, url|
          project.project_feature.update_attribute("#{method_name}_access_level", ProjectFeature::PRIVATE)
          visit url
          expect(page.status_code).to eq(200)
        end
      end
    end

    context 'admin user' do
      before do
        non_member.update_attribute(:admin, true)
        sign_in(non_member)
      end

      it 'renders 404 if feature is disabled' do
        tools.each do |method_name, url|
          project.project_feature.update_attribute("#{method_name}_access_level", ProjectFeature::DISABLED)
          visit url
          expect(page.status_code).to eq(404)
        end
      end

      it 'renders 200 if feature is enabled only for team members' do
        project.team.truncate

        tools.each do |method_name, url|
          project.project_feature.update_attribute("#{method_name}_access_level", ProjectFeature::PRIVATE)
          visit url
          expect(page.status_code).to eq(200)
        end
      end
    end
  end

  describe 'repository visibility', js: true do
    before do
      project.team << [member, :master]
      sign_in(member)
      visit edit_project_path(project)
    end

    it "disables repository related features" do
      select "Disabled", from: "project_project_feature_attributes_repository_access_level"

      expect(find(".edit-project")).to have_selector("select.disabled", count: 2)
    end

    it "shows empty features project homepage" do
      select "Disabled", from: "project_project_feature_attributes_repository_access_level"
      select "Disabled", from: "project_project_feature_attributes_issues_access_level"
      select "Disabled", from: "project_project_feature_attributes_wiki_access_level"

      click_button "Save changes"
      wait_for_requests

      visit project_path(project)

      expect(page).to have_content "Customize your workflow!"
    end

    it "hides project activity tabs" do
      select "Disabled", from: "project_project_feature_attributes_repository_access_level"
      select "Disabled", from: "project_project_feature_attributes_issues_access_level"
      select "Disabled", from: "project_project_feature_attributes_wiki_access_level"

      click_button "Save changes"
      wait_for_requests

      visit activity_project_path(project)

      page.within(".event-filter") do
        expect(page).to have_selector("a", count: 2)
        expect(page).not_to have_content("Push events")
        expect(page).not_to have_content("Merge events")
        expect(page).not_to have_content("Comments")
      end
    end

    # Regression spec for https://gitlab.com/gitlab-org/gitlab-ce/issues/25272
    it "hides comments activity tab only on disabled issues, merge requests and repository" do
      select "Disabled", from: "project_project_feature_attributes_issues_access_level"

      save_changes_and_check_activity_tab do
        expect(page).to have_content("Comments")
      end

      visit edit_project_path(project)

      select "Disabled", from: "project_project_feature_attributes_merge_requests_access_level"

      save_changes_and_check_activity_tab do
        expect(page).to have_content("Comments")
      end

      visit edit_project_path(project)

      select "Disabled", from: "project_project_feature_attributes_repository_access_level"

      save_changes_and_check_activity_tab do
        expect(page).not_to have_content("Comments")
      end

      visit edit_project_path(project)
    end

    def save_changes_and_check_activity_tab
      click_button "Save changes"
      wait_for_requests

      visit activity_project_path(project)

      page.within(".event-filter") do
        yield
      end
    end
  end

  # Regression spec for https://gitlab.com/gitlab-org/gitlab-ce/issues/24056
  describe 'project statistic visibility' do
    let!(:project) { create(:project, :private) }

    before do
      project.team << [member, :guest]
      sign_in(member)
      visit project_path(project)
    end

    it "does not show project statistic for guest" do
      expect(page).not_to have_selector('.project-stats')
    end
  end
end
