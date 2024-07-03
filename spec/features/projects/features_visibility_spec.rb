# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit Project Settings', feature_category: :groups_and_projects do
  let(:member) { create(:user) }
  let!(:project) { create(:project, :public, :repository) }
  let!(:issue) { create(:issue, project: project) }
  let(:non_member) { create(:user) }

  # Sidebar nav links are only visible after hovering over or expanding the
  # section that contains them (if it exists). Finding visible and hidden
  # nav links allows us to avoid doing that.
  let(:visibility_all) { { visible: :all } }

  describe 'project features visibility selectors', :js do
    before do
      project.add_maintainer(member)
      sign_in(member)
    end

    tools = { builds: "pipelines", issues: "issues", wiki: "wiki", snippets: "snippets", merge_requests: "merge_requests", analytics: "project-cycle-analytics" }

    tools.each do |tool_name, shortcut_name|
      describe "feature #{tool_name}" do
        it 'toggles visibility' do
          visit edit_project_path(project)

          # disable by clicking toggle
          toggle_feature_off(tool_name)
          click_save_changes
          wait_for_requests
          expect(page).not_to have_selector(".shortcuts-#{shortcut_name}", **visibility_all)

          # re-enable by clicking toggle again
          toggle_feature_on(tool_name)
          click_save_changes
          wait_for_requests
          expect(page).to have_selector(".shortcuts-#{shortcut_name}", **visibility_all)
        end
      end
    end

    context 'When external issue tracker is enabled and issues enabled on project settings' do
      it 'does not hide issues tab and hides labels tab' do
        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive(:external_issue_tracker).and_return(Integrations::Jira.new)
        end

        visit project_path(project)

        expect(page).to have_selector('.shortcuts-issues', **visibility_all)
        expect(page).not_to have_selector('.shortcuts-labels', **visibility_all)
      end
    end

    context 'When external issue tracker is enabled and issues disabled on project settings' do
      before do
        project.issues_enabled = false
        project.save!
        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive(:external_issue_tracker).and_return(Integrations::Jira.new)
        end
      end

      it 'hides issues tab' do
        visit project_path(project)

        expect(page).not_to have_selector('.shortcuts-issues', **visibility_all)
        expect(page).not_to have_selector('.shortcuts-labels', **visibility_all)
      end
    end

    context "pipelines subtabs" do
      it "shows builds when enabled" do
        visit project_pipelines_path(project)

        expect(page).to have_selector(".shortcuts-builds", **visibility_all)
      end

      it "hides builds when disabled" do
        allow(Ability).to receive(:allowed?).and_return(true)
        allow(Ability).to receive(:allowed?).with(member, :read_build, project).and_return(false)

        visit project_pipelines_path(project)

        expect(page).not_to have_selector(".shortcuts-builds", **visibility_all)
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
        wiki: wiki_path(project.wiki),
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
        project.save!

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
        enable_admin_mode!(non_member)
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

  describe 'repository visibility', :js do
    before do
      project.add_maintainer(member)
      sign_in(member)
      visit edit_project_path(project)
    end

    it "disables repository related features" do
      toggle_feature_off('repository')

      click_save_changes
      expect(find_by_testid("visibility-features-permissions-content")).to have_selector(".gl-toggle.is-disabled", minimum: 3)
    end

    it "shows empty features project homepage" do
      toggle_feature_off('repository')
      toggle_feature_off('issues')
      toggle_feature_off('wiki')

      click_save_changes
      wait_for_requests

      visit project_path(project)

      expect(page).to have_content "joined project"
    end

    it "hides project activity tabs" do
      toggle_feature_off('repository')
      toggle_feature_off('issues')
      toggle_feature_off('wiki')

      click_save_changes
      wait_for_requests

      visit activity_project_path(project)

      page.within(".event-filter") do
        expect(page).to have_content("All")
        expect(page).not_to have_content("Push events")
        expect(page).not_to have_content("Merge events")
        expect(page).not_to have_content("Comments")
      end
    end

    # Regression spec for https://gitlab.com/gitlab-org/gitlab-foss/issues/25272
    it "hides comments activity tab only on disabled issues, merge requests and repository" do
      toggle_feature_off('issues')

      save_changes_and_check_activity_tab do
        expect(page).to have_content("Comments")
      end

      visit edit_project_path(project)

      toggle_feature_off('merge_requests')

      save_changes_and_check_activity_tab do
        expect(page).to have_content("Comments")
      end

      visit edit_project_path(project)

      toggle_feature_off('repository')

      save_changes_and_check_activity_tab do
        expect(page).not_to have_content("Comments")
      end

      visit edit_project_path(project)
    end

    def save_changes_and_check_activity_tab
      click_save_changes
      wait_for_requests

      visit activity_project_path(project)

      page.within(".event-filter") do
        yield
      end
    end
  end

  # Regression spec for https://gitlab.com/gitlab-org/gitlab-foss/issues/24056
  describe 'project statistic visibility' do
    let!(:project) { create(:project, :private) }

    before do
      project.add_guest(member)
      sign_in(member)
      visit project_path(project)
    end

    it "does not show project statistic for guest" do
      expect(page).not_to have_selector('.project-stats')
    end
  end

  def toggle_feature_off(feature_name)
    find(".project-feature-controls[data-for=\"project[project_feature_attributes][#{feature_name}_access_level]\"] .gl-toggle.is-checked").click
  end

  def toggle_feature_on(feature_name)
    find(".project-feature-controls[data-for=\"project[project_feature_attributes][#{feature_name}_access_level]\"] .gl-toggle:not(.is-checked)").click
  end

  def click_save_changes
    within_testid('visibility-features-permissions-content') do
      click_button 'Save changes'
    end
  end
end
