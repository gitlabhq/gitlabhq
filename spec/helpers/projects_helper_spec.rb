# frozen_string_literal: true

require 'spec_helper'

describe ProjectsHelper do
  include ProjectForksHelper

  describe '#error_tracking_setting_project_json' do
    let(:project) { create(:project) }

    context 'error tracking setting does not exist' do
      before do
        helper.instance_variable_set(:@project, project)
      end

      it 'returns nil' do
        expect(helper.error_tracking_setting_project_json).to be_nil
      end
    end

    context 'error tracking setting exists' do
      let!(:error_tracking_setting) { create(:project_error_tracking_setting, project: project) }

      context 'api_url present' do
        let(:json) do
          {
            name: error_tracking_setting.project_name,
            organization_name: error_tracking_setting.organization_name,
            organization_slug: error_tracking_setting.organization_slug,
            slug: error_tracking_setting.project_slug
          }.to_json
        end

        before do
          helper.instance_variable_set(:@project, project)
        end

        it 'returns error tracking json' do
          expect(helper.error_tracking_setting_project_json).to eq(json)
        end
      end

      context 'api_url not present' do
        before do
          project.error_tracking_setting.api_url = nil
          project.error_tracking_setting.enabled = false

          helper.instance_variable_set(:@project, project)
        end

        it 'returns nil' do
          expect(helper.error_tracking_setting_project_json).to be_nil
        end
      end
    end
  end

  describe "#project_status_css_class" do
    it "returns appropriate class" do
      expect(project_status_css_class("started")).to eq("table-active")
      expect(project_status_css_class("failed")).to eq("table-danger")
      expect(project_status_css_class("finished")).to eq("table-success")
    end
  end

  describe "can_change_visibility_level?" do
    let(:project) { create(:project) }
    let(:user) { create(:project_member, :reporter, user: create(:user), project: project).user }
    let(:forked_project) { fork_project(project, user) }

    it "returns false if there are no appropriate permissions" do
      allow(helper).to receive(:can?) { false }

      expect(helper.can_change_visibility_level?(project, user)).to be_falsey
    end

    it "returns true if there are permissions and it is not fork" do
      allow(helper).to receive(:can?) { true }

      expect(helper.can_change_visibility_level?(project, user)).to be_truthy
    end

    it 'allows visibility level to be changed if the project is forked' do
      allow(helper).to receive(:can?).with(user, :change_visibility_level, project) { true }
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      fork_project(project)

      expect(helper.can_change_visibility_level?(project, user)).to be_truthy
    end

    context "forks" do
      it "returns false if there are permissions and origin project is PRIVATE" do
        allow(helper).to receive(:can?) { true }

        project.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        expect(helper.can_change_visibility_level?(forked_project, user)).to be_falsey
      end

      it "returns true if there are permissions and origin project is INTERNAL" do
        allow(helper).to receive(:can?) { true }

        project.update(visibility_level: Gitlab::VisibilityLevel::INTERNAL)

        expect(helper.can_change_visibility_level?(forked_project, user)).to be_truthy
      end
    end
  end

  describe '#can_disable_emails?' do
    let(:project) { create(:project) }
    let(:user) { create(:project_member, :maintainer, user: create(:user), project: project).user }

    it 'returns true for the project owner' do
      allow(helper).to receive(:can?).with(project.owner, :set_emails_disabled, project) { true }

      expect(helper.can_disable_emails?(project, project.owner)).to be_truthy
    end

    it 'returns false for anyone else' do
      allow(helper).to receive(:can?).with(user, :set_emails_disabled, project) { false }

      expect(helper.can_disable_emails?(project, user)).to be_falsey
    end

    it 'returns false if group emails disabled' do
      project = create(:project, group: create(:group))
      allow(project.group).to receive(:emails_disabled?).and_return(true)

      expect(helper.can_disable_emails?(project, project.owner)).to be_falsey
    end
  end

  describe "readme_cache_key" do
    let(:project) { create(:project, :repository) }

    before do
      helper.instance_variable_set(:@project, project)
    end

    it "returns a valid cach key" do
      expect(helper.send(:readme_cache_key)).to eq("#{project.full_path}-#{project.commit.id}-readme")
    end

    it "returns a valid cache key if HEAD does not exist" do
      allow(project).to receive(:commit) { nil }

      expect(helper.send(:readme_cache_key)).to eq("#{project.full_path}-nil-readme")
    end
  end

  describe "#project_list_cache_key", :clean_gitlab_redis_shared_state do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).with(user, :read_cross_project) { true }
      allow(user).to receive(:max_member_access_for_project).and_return(40)
      allow(Gitlab::I18n).to receive(:locale).and_return('es')
    end

    it "includes the route" do
      expect(helper.project_list_cache_key(project)).to include(project.route.cache_key)
    end

    it "includes the project" do
      expect(helper.project_list_cache_key(project)).to include(project.cache_key)
    end

    it "includes the last activity date" do
      expect(helper.project_list_cache_key(project)).to include(project.last_activity_date)
    end

    it "includes the controller name" do
      expect(helper.controller).to receive(:controller_name).and_return("testcontroller")

      expect(helper.project_list_cache_key(project)).to include("testcontroller")
    end

    it "includes the controller action" do
      expect(helper.controller).to receive(:action_name).and_return("testaction")

      expect(helper.project_list_cache_key(project)).to include("testaction")
    end

    it "includes the application settings" do
      settings = Gitlab::CurrentSettings.current_application_settings

      expect(helper.project_list_cache_key(project)).to include(settings.cache_key)
    end

    it "includes a version" do
      expect(helper.project_list_cache_key(project).last).to start_with('v')
    end

    it 'includes wether or not the user can read cross project' do
      expect(helper.project_list_cache_key(project)).to include('cross-project:true')
    end

    it "includes the pipeline status when there is a status" do
      create(:ci_pipeline, :success, project: project, sha: project.commit.sha)

      expect(helper.project_list_cache_key(project)).to include("pipeline-status/#{project.commit.sha}-success")
    end

    it "includes the user locale" do
      expect(helper.project_list_cache_key(project)).to include('es')
    end

    it "includes the user max member access" do
      expect(helper.project_list_cache_key(project)).to include('access:40')
    end
  end

  describe '#load_pipeline_status' do
    it 'loads the pipeline status in batch' do
      project = build(:project)

      helper.load_pipeline_status([project])
      # Skip lazy loading of the `pipeline_status` attribute
      pipeline_status = project.instance_variable_get('@pipeline_status')

      expect(pipeline_status).to be_a(Gitlab::Cache::Ci::ProjectPipelineStatus)
    end
  end

  describe '#show_no_ssh_key_message?' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'user has no keys' do
      it 'returns true' do
        expect(helper.show_no_ssh_key_message?).to be_truthy
      end
    end

    context 'user has an ssh key' do
      it 'returns false' do
        create(:personal_key, user: user)

        expect(helper.show_no_ssh_key_message?).to be_falsey
      end
    end
  end

  describe '#show_no_password_message?' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'user has password set' do
      it 'returns false' do
        expect(helper.show_no_password_message?).to be_falsey
      end
    end

    context 'user has hidden the message' do
      it 'returns false' do
        allow(helper).to receive(:cookies).and_return(hide_no_password_message: true)

        expect(helper.show_no_password_message?).to be_falsey
      end
    end

    context 'user requires a password for Git' do
      it 'returns true' do
        allow(user).to receive(:require_password_creation_for_git?).and_return(true)

        expect(helper.show_no_password_message?).to be_truthy
      end
    end

    context 'user requires a personal access token for Git' do
      it 'returns true' do
        allow(user).to receive(:require_password_creation_for_git?).and_return(false)
        allow(user).to receive(:require_personal_access_token_creation_for_git_auth?).and_return(true)

        expect(helper.show_no_password_message?).to be_truthy
      end
    end
  end

  describe '#link_to_set_password' do
    let(:user) { create(:user, password_automatically_set: true) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'password authentication is enabled for Git' do
      it 'returns link to set a password' do
        stub_application_setting(password_authentication_enabled_for_git?: true)

        expect(helper.link_to_set_password).to match %r{<a href="#{edit_profile_password_path}">set a password</a>}
      end
    end

    context 'password authentication is disabled for Git' do
      it 'returns link to create a personal access token' do
        stub_application_setting(password_authentication_enabled_for_git?: false)

        expect(helper.link_to_set_password).to match %r{<a href="#{profile_personal_access_tokens_path}">create a personal access token</a>}
      end
    end
  end

  describe '#link_to_project' do
    let(:group)   { create(:group, name: 'group name with space') }
    let(:project) { create(:project, group: group, name: 'project name with space') }

    subject { link_to_project(project) }

    it 'returns an HTML link to the project' do
      expect(subject).to match(%r{/#{group.full_path}/#{project.path}})
      expect(subject).to include('group name with space /')
      expect(subject).to include('project name with space')
    end
  end

  describe '#link_to_member_avatar' do
    let(:user) { build_stubbed(:user) }
    let(:expected) { double }

    before do
      expect(helper).to receive(:avatar_icon_for_user).with(user, 16).and_return(expected)
    end

    it 'returns image tag for member avatar' do
      expect(helper).to receive(:image_tag).with(expected, { width: 16, class: %w[avatar avatar-inline s16], alt: "", "data-src" => anything })

      helper.link_to_member_avatar(user)
    end

    it 'returns image tag with avatar class' do
      expect(helper).to receive(:image_tag).with(expected, { width: 16, class: %w[avatar avatar-inline s16 any-avatar-class], alt: "", "data-src" => anything })

      helper.link_to_member_avatar(user, avatar_class: "any-avatar-class")
    end
  end

  describe '#link_to_member' do
    let(:group)   { build_stubbed(:group) }
    let(:project) { build_stubbed(:project, group: group) }
    let(:user)    { build_stubbed(:user, name: '<h1>Administrator</h1>') }

    describe 'using the default options' do
      it 'returns an HTML link to the user' do
        link = helper.link_to_member(project, user)

        expect(link).to match(%r{/#{user.username}})
      end

      it 'HTML escapes the name of the user' do
        link = helper.link_to_member(project, user)

        expect(link).to include(ERB::Util.html_escape(user.name))
        expect(link).not_to include(user.name)
      end
    end
  end

  describe 'default_clone_protocol' do
    context 'when user is not logged in and gitlab protocol is HTTP' do
      it 'returns HTTP' do
        allow(helper).to receive(:current_user).and_return(nil)

        expect(helper.send(:default_clone_protocol)).to eq('http')
      end
    end

    context 'when user is not logged in and gitlab protocol is HTTPS' do
      it 'returns HTTPS' do
        stub_config_setting(protocol: 'https')
        allow(helper).to receive(:current_user).and_return(nil)

        expect(helper.send(:default_clone_protocol)).to eq('https')
      end
    end
  end

  describe '#last_push_event' do
    let(:user) { double(:user, fork_of: nil) }
    let(:project) { double(:project, id: 1) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      helper.instance_variable_set(:@project, project)
    end

    context 'when there is no current_user' do
      let(:user) { nil }

      it 'returns nil' do
        expect(helper.last_push_event).to eq(nil)
      end
    end

    it 'returns recent push on the current project' do
      event = double(:event)
      expect(user).to receive(:recent_push).with(project).and_return(event)

      expect(helper.last_push_event).to eq(event)
    end
  end

  describe '#get_project_nav_tabs' do
    let(:project) { create(:project) }
    let(:user)    { create(:user) }

    before do
      allow(helper).to receive(:can?) { true }
    end

    subject do
      helper.send(:get_project_nav_tabs, project, user)
    end

    context 'when builds feature is enabled' do
      before do
        allow(project).to receive(:builds_enabled?).and_return(true)
      end

      it "does include pipelines tab" do
        is_expected.to include(:pipelines)
      end
    end

    context 'when builds feature is disabled' do
      before do
        allow(project).to receive(:builds_enabled?).and_return(false)
      end

      context 'when user has access to builds' do
        it "does include pipelines tab" do
          is_expected.to include(:pipelines)
        end
      end

      context 'when user does not have access to builds' do
        before do
          allow(helper).to receive(:can?) { false }
        end

        it "does not include pipelines tab" do
          is_expected.not_to include(:pipelines)
        end
      end
    end

    context 'when project has external wiki' do
      it 'includes external wiki tab' do
        project.create_external_wiki_service(active: true, properties: { 'external_wiki_url' => 'https://gitlab.com' })

        is_expected.to include(:external_wiki)
      end
    end

    context 'when project does not have external wiki' do
      it 'does not include external wiki tab' do
        expect(project.external_wiki).to be_nil
        is_expected.not_to include(:external_wiki)
      end
    end
  end

  describe '#show_projects' do
    let(:projects) do
      create(:project)
      Project.all
    end

    before do
      stub_feature_flags(project_list_filter_bar: false)
    end

    it 'returns true when there are projects' do
      expect(helper.show_projects?(projects, {})).to eq(true)
    end

    it 'returns true when there are no projects but a name is given' do
      expect(helper.show_projects?(Project.none, name: 'foo')).to eq(true)
    end

    it 'returns true when there are no projects but personal is present' do
      expect(helper.show_projects?(Project.none, personal: 'true')).to eq(true)
    end

    it 'returns false when there are no projects and there is no name' do
      expect(helper.show_projects?(Project.none, {})).to eq(false)
    end
  end

  describe('#push_to_create_project_command') do
    let(:user) { create(:user, username: 'john') }

    it 'returns the command to push to create project over HTTP' do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:enabled_git_access_protocol) { 'http' }

      expect(helper.push_to_create_project_command(user)).to eq('git push --set-upstream http://test.host/john/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD)')
    end

    it 'returns the command to push to create project over SSH' do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:enabled_git_access_protocol) { 'ssh' }

      expect(helper.push_to_create_project_command(user)).to eq("git push --set-upstream #{Gitlab.config.gitlab.user}@localhost:john/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD)")
    end
  end

  describe '#any_projects?' do
    let!(:project) { create(:project) }

    it 'returns true when projects will be returned' do
      expect(helper.any_projects?(Project.all)).to eq(true)
    end

    it 'returns false when no projects will be returned' do
      expect(helper.any_projects?(Project.none)).to eq(false)
    end

    it 'returns true when using a non-empty Array' do
      expect(helper.any_projects?([project])).to eq(true)
    end

    it 'returns false when using an empty Array' do
      expect(helper.any_projects?([])).to eq(false)
    end

    it 'only executes a single query when a LIMIT is applied' do
      relation = Project.limit(1)
      recorder = ActiveRecord::QueryRecorder.new do
        2.times do
          helper.any_projects?(relation)
        end
      end

      expect(recorder.count).to eq(1)
    end
  end

  describe '#git_user_name' do
    let(:user) { double(:user, name: 'John "A" Doe53') }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'parses quotes in name' do
      expect(helper.send(:git_user_name)).to eq('John \"A\" Doe53')
    end
  end

  describe '#git_user_email' do
    context 'not logged-in' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns your@email.com' do
        expect(helper.send(:git_user_email)).to eq('your@email.com')
      end
    end

    context 'user logged in' do
      let(:user) { create(:user) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'user has no configured commit email' do
        it 'returns the primary email' do
          expect(helper.send(:git_user_email)).to eq(user.email)
        end
      end

      context 'user has a configured commit email' do
        before do
          confirmed_email = create(:email, :confirmed, user: user)
          user.update(commit_email: confirmed_email)
        end

        it 'returns the commit email' do
          expect(helper.send(:git_user_email)).to eq(user.commit_email)
        end
      end
    end
  end

  describe 'show_xcode_link' do
    let!(:project) { create(:project) }
    let(:mac_ua) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36' }
    let(:ios_ua) { 'Mozilla/5.0 (iPad; CPU OS 5_1_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B206 Safari/7534.48.3' }

    context 'when the repository is xcode compatible' do
      before do
        allow(project.repository).to receive(:xcode_project?).and_return(true)
      end

      it 'returns false if the visitor is not using macos' do
        allow(helper).to receive(:browser).and_return(Browser.new(ios_ua))

        expect(helper.show_xcode_link?(project)).to eq(false)
      end

      it 'returns true if the visitor is using macos' do
        allow(helper).to receive(:browser).and_return(Browser.new(mac_ua))

        expect(helper.show_xcode_link?(project)).to eq(true)
      end
    end

    context 'when the repository is not xcode compatible' do
      before do
        allow(project.repository).to receive(:xcode_project?).and_return(false)
      end

      it 'returns false if the visitor is not using macos' do
        allow(helper).to receive(:browser).and_return(Browser.new(ios_ua))

        expect(helper.show_xcode_link?(project)).to eq(false)
      end

      it 'returns false if the visitor is using macos' do
        allow(helper).to receive(:browser).and_return(Browser.new(mac_ua))

        expect(helper.show_xcode_link?(project)).to eq(false)
      end
    end
  end

  describe 'link_to_bfg' do
    subject { helper.link_to_bfg }

    it 'generates a hardcoded link to the BFG Repo-Cleaner' do
      result = helper.link_to_bfg
      doc = Nokogiri::HTML.fragment(result)

      expect(doc.children.size).to eq(1)

      link = doc.children.first

      aggregate_failures do
        expect(result).to be_html_safe

        expect(link.name).to eq('a')
        expect(link[:target]).to eq('_blank')
        expect(link[:rel]).to eq('noopener noreferrer')
        expect(link[:href]).to eq('https://rtyley.github.io/bfg-repo-cleaner/')
        expect(link.inner_html).to eq('BFG')

        expect(result).to be_html_safe
      end
    end
  end

  describe '#explore_projects_tab?' do
    subject { helper.explore_projects_tab? }

    it 'returns true when on the "All" tab under "Explore projects"' do
      allow(@request).to receive(:path) { explore_projects_path }

      expect(subject).to be_truthy
    end

    it 'returns true when on the "Trending" tab under "Explore projects"' do
      allow(@request).to receive(:path) { trending_explore_projects_path }

      expect(subject).to be_truthy
    end

    it 'returns true when on the "Starred" tab under "Explore projects"' do
      allow(@request).to receive(:path) { starred_explore_projects_path }

      expect(subject).to be_truthy
    end

    it 'returns false when on the "Your projects" tab' do
      allow(@request).to receive(:path) { dashboard_projects_path }

      expect(subject).to be_falsey
    end
  end

  describe '#show_merge_request_count' do
    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(project_list_show_mr_count: true)
      end

      it 'returns true if compact mode is disabled' do
        expect(helper.show_merge_request_count?).to be_truthy
      end

      it 'returns false if compact mode is enabled' do
        expect(helper.show_merge_request_count?(compact_mode: true)).to be_falsey
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(project_list_show_mr_count: false)
      end

      it 'always returns false' do
        expect(helper.show_merge_request_count?(disabled: false)).to be_falsy
        expect(helper.show_merge_request_count?(disabled: true)).to be_falsy
      end
    end

    context 'disabled flag' do
      before do
        stub_feature_flags(project_list_show_mr_count: true)
      end

      it 'returns false if disabled flag is true' do
        expect(helper.show_merge_request_count?(disabled: true)).to be_falsey
      end

      it 'returns true if disabled flag is false' do
        expect(helper.show_merge_request_count?).to be_truthy
      end
    end
  end

  describe '#show_issue_count?' do
    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(project_list_show_issue_count: true)
      end

      it 'returns true if compact mode is disabled' do
        expect(helper.show_issue_count?).to be_truthy
      end

      it 'returns false if compact mode is enabled' do
        expect(helper.show_issue_count?(compact_mode: true)).to be_falsey
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(project_list_show_issue_count: false)
      end

      it 'always returns false' do
        expect(helper.show_issue_count?(disabled: false)).to be_falsy
        expect(helper.show_issue_count?(disabled: true)).to be_falsy
      end
    end

    context 'disabled flag' do
      before do
        stub_feature_flags(project_list_show_issue_count: true)
      end

      it 'returns false if disabled flag is true' do
        expect(helper.show_issue_count?(disabled: true)).to be_falsey
      end

      it 'returns true if disabled flag is false' do
        expect(helper.show_issue_count?).to be_truthy
      end
    end
  end

  describe '#show_auto_devops_implicitly_enabled_banner?' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { create(:user) }

    let(:feature_visibilities) do
      {
        enabled: ProjectFeature::ENABLED,
        disabled: ProjectFeature::DISABLED
      }
    end

    where(:global_setting, :project_setting, :builds_visibility, :gitlab_ci_yml, :user_access, :result) do
      # With ADO implicitly enabled scenarios
      true | nil | :disabled | true  | :developer  | false
      true | nil | :disabled | true  | :maintainer | false
      true | nil | :disabled | true  | :owner      | false

      true | nil | :disabled | false | :developer  | false
      true | nil | :disabled | false | :maintainer | false
      true | nil | :disabled | false | :owner      | false

      true | nil | :enabled  | true  | :developer  | false
      true | nil | :enabled  | true  | :maintainer | false
      true | nil | :enabled  | true  | :owner      | false

      true | nil | :enabled  | false | :developer  | false
      true | nil | :enabled  | false | :maintainer | true
      true | nil | :enabled  | false | :owner      | true

      # With ADO enabled scenarios
      true | true | :disabled | true  | :developer  | false
      true | true | :disabled | true  | :maintainer | false
      true | true | :disabled | true  | :owner      | false

      true | true | :disabled | false | :developer  | false
      true | true | :disabled | false | :maintainer | false
      true | true | :disabled | false | :owner      | false

      true | true | :enabled  | true  | :developer  | false
      true | true | :enabled  | true  | :maintainer | false
      true | true | :enabled  | true  | :owner      | false

      true | true | :enabled  | false | :developer  | false
      true | true | :enabled  | false | :maintainer | false
      true | true | :enabled  | false | :owner      | false

      # With ADO disabled scenarios
      true | false | :disabled | true  | :developer  | false
      true | false | :disabled | true  | :maintainer | false
      true | false | :disabled | true  | :owner      | false

      true | false | :disabled | false | :developer  | false
      true | false | :disabled | false | :maintainer | false
      true | false | :disabled | false | :owner      | false

      true | false | :enabled  | true  | :developer  | false
      true | false | :enabled  | true  | :maintainer | false
      true | false | :enabled  | true  | :owner      | false

      true | false | :enabled  | false | :developer  | false
      true | false | :enabled  | false | :maintainer | false
      true | false | :enabled  | false | :owner      | false
    end

    def grant_user_access(project, user, access)
      case access
      when :developer, :maintainer
        project.add_user(user, access)
      when :owner
        project.namespace.update(owner: user)
      end
    end

    with_them do
      let(:project) do
        if project_setting.nil?
          create(:project, :repository)
        else
          create(:project, :repository, :auto_devops)
        end
      end

      before do
        stub_application_setting(auto_devops_enabled: global_setting)

        allow_any_instance_of(Repository).to receive(:gitlab_ci_yml).and_return(gitlab_ci_yml)

        grant_user_access(project, user, user_access)
        project.project_feature.update_attribute(:builds_access_level, feature_visibilities[builds_visibility])
        project.auto_devops.update_attribute(:enabled, project_setting) unless project_setting.nil?
      end

      subject { helper.show_auto_devops_implicitly_enabled_banner?(project, user) }

      it { is_expected.to eq(result) }
    end
  end

  describe '#can_import_members?' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:owner) { project.owner }

    before do
      helper.instance_variable_set(:@project, project)
    end

    it 'returns false if user cannot admin_project_member' do
      allow(helper).to receive(:current_user) { user }
      expect(helper.can_import_members?).to eq false
    end

    it 'returns true if user can admin_project_member' do
      allow(helper).to receive(:current_user) { owner }
      expect(helper.can_import_members?).to eq true
    end
  end

  describe '#metrics_external_dashboard_url' do
    let(:project) { create(:project) }

    before do
      helper.instance_variable_set(:@project, project)
    end

    context 'metrics_setting exists' do
      it 'returns external_dashboard_url' do
        metrics_setting = create(:project_metrics_setting, project: project)

        expect(helper.metrics_external_dashboard_url).to eq(metrics_setting.external_dashboard_url)
      end
    end

    context 'metrics_setting does not exist' do
      it 'returns nil' do
        expect(helper.metrics_external_dashboard_url).to eq(nil)
      end
    end
  end

  describe '#grafana_integration_url' do
    let(:project) { create(:project) }

    before do
      helper.instance_variable_set(:@project, project)
    end

    subject { helper.grafana_integration_url }

    it { is_expected.to eq(nil) }

    context 'grafana integration exists' do
      let!(:grafana_integration) { create(:grafana_integration, project: project) }

      it { is_expected.to eq(grafana_integration.grafana_url) }
    end
  end

  describe '#grafana_integration_token' do
    let(:project) { create(:project) }

    before do
      helper.instance_variable_set(:@project, project)
    end

    subject { helper.grafana_integration_token }

    it { is_expected.to eq(nil) }

    context 'grafana integration exists' do
      let!(:grafana_integration) { create(:grafana_integration, project: project) }

      it { is_expected.to eq(grafana_integration.token) }
    end
  end

  describe '#grafana_integration_enabled?' do
    let(:project) { create(:project) }

    before do
      helper.instance_variable_set(:@project, project)
    end

    subject { helper.grafana_integration_enabled? }

    it { is_expected.to eq(nil) }

    context 'grafana integration exists' do
      let!(:grafana_integration) { create(:grafana_integration, project: project) }

      it { is_expected.to eq(grafana_integration.enabled) }
    end
  end
end
