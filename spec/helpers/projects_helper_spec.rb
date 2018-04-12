require 'spec_helper'

describe ProjectsHelper do
  include ProjectForksHelper

  describe "#project_status_css_class" do
    it "returns appropriate class" do
      expect(project_status_css_class("started")).to eq("active")
      expect(project_status_css_class("failed")).to eq("danger")
      expect(project_status_css_class("finished")).to eq("success")
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
    end

    it "includes the route" do
      expect(helper.project_list_cache_key(project)).to include(project.route.cache_key)
    end

    it "includes the project" do
      expect(helper.project_list_cache_key(project)).to include(project.cache_key)
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

  describe '#link_to_member_avatar' do
    let(:user) { build_stubbed(:user) }
    let(:expected) { double }

    before do
      expect(helper).to receive(:avatar_icon_for_user).with(user, 16).and_return(expected)
    end

    it 'returns image tag for member avatar' do
      expect(helper).to receive(:image_tag).with(expected, { width: 16, class: ["avatar", "avatar-inline", "s16"], alt: "", "data-src" => anything })

      helper.link_to_member_avatar(user)
    end

    it 'returns image tag with avatar class' do
      expect(helper).to receive(:image_tag).with(expected, { width: 16, class: ["avatar", "avatar-inline", "s16", "any-avatar-class"], alt: "", "data-src" => anything })

      helper.link_to_member_avatar(user, avatar_class: "any-avatar-class")
    end
  end

  describe '#link_to_member' do
    let(:group)   { build_stubbed(:group) }
    let(:project) { build_stubbed(:project, group: group) }
    let(:user)    { build_stubbed(:user) }

    describe 'using the default options' do
      it 'returns an HTML link to the user' do
        link = helper.link_to_member(project, user)

        expect(link).to match(%r{/#{user.username}})
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

    context 'when gitlab.config.kerberos is enabled and user is logged in' do
      it 'returns krb5 as default protocol' do
        allow(Gitlab.config.kerberos).to receive(:enabled).and_return(true)
        allow(helper).to receive(:current_user).and_return(double)

        expect(helper.send(:default_clone_protocol)).to eq('krb5')
      end
    end
  end

  describe '#sanitized_import_error' do
    let(:project) { create(:project, :repository) }

    before do
      allow(project).to receive(:repository_storage_path).and_return('/base/repo/path')
      allow(Settings.shared).to receive(:[]).with('path').and_return('/base/repo/export/path')
    end

    it 'removes the repo path' do
      repo = '/base/repo/path/namespace/test.git'
      import_error = "Could not clone #{repo}\n"

      expect(sanitize_repo_path(project, import_error)).to eq('Could not clone [REPOS PATH]/namespace/test.git')
    end

    it 'removes the temporary repo path used for uploads/exports' do
      repo = '/base/repo/export/path/tmp/project_exports/uploads/test.tar.gz'
      import_error = "Unable to decompress #{repo}\n"

      expect(sanitize_repo_path(project, import_error)).to eq('Unable to decompress [REPO EXPORT PATH]/uploads/test.tar.gz')
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

      it "do not include pipelines tab" do
        is_expected.not_to include(:pipelines)
      end
    end
  end

  describe '#show_projects' do
    let(:projects) do
      create(:project)
      Project.all
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

      expect(helper.push_to_create_project_command(user)).to eq('git push --set-upstream git@localhost:john/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD)')
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
end
