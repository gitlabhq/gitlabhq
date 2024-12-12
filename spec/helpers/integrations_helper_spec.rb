# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IntegrationsHelper, feature_category: :integrations do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_refind(:project) { create(:project) }

  shared_examples 'is defined for each integration event' do
    Integration.available_integration_names.each do |integration|
      events = Integration.integration_name_to_model(integration).new.configurable_events
      events.each do |event|
        context "when integration is #{integration}, event is #{event}" do
          let(:integration) { integration }
          let(:event) { event }

          it { is_expected.not_to be_nil }
        end
      end
    end
  end

  describe '#integration_event_title' do
    subject { helper.integration_event_title(event) }

    it_behaves_like 'is defined for each integration event'
  end

  describe '#integration_event_description' do
    subject { helper.integration_event_description(integration, event) }

    it_behaves_like 'is defined for each integration event'

    context 'when integration is Jira' do
      let(:integration) { Integrations::Jira.new }
      let(:event) { 'merge_request_events' }

      it { is_expected.to include('Jira') }
    end

    context 'when integration is Team City' do
      let(:integration) { Integrations::Teamcity.new }
      let(:event) { 'merge_request_events' }

      it { is_expected.to include('TeamCity') }
    end
  end

  describe '#integration_form_data' do
    before do
      allow(helper).to receive_messages(
        request: double(referer: '/services')
      )
    end

    let(:fields) do
      [
        :id,
        :project_id,
        :group_id,
        :manual_activation,
        :activated,
        :activate_disabled,
        :type,
        :merge_request_events,
        :commit_events,
        :enable_comments,
        :comment_detail,
        :learn_more_path,
        :about_pricing_url,
        :trigger_events,
        :fields,
        :inherit_from_id,
        :integration_level,
        :editable,
        :cancel_path,
        :can_test,
        :test_path,
        :reset_path,
        :form_path,
        :redirect_to
      ]
    end

    let(:jira_fields) do
      [
        :jira_issue_transition_automatic,
        :jira_issue_transition_id
      ]
    end

    let(:slack_app_fields) do
      [
        :upgrade_slack_url,
        :should_upgrade_slack
      ]
    end

    subject { helper.integration_form_data(integration) }

    context 'with a GitLab for Slack App integration' do
      let(:integration) { build(:gitlab_slack_application_integration, project: project) }

      let(:redirect_url) do
        "http://test.host/#{project.full_path}/-/settings/slack/slack_auth"
      end

      before do
        allow(helper).to receive(:slack_auth_project_settings_slack_url).and_return(redirect_url)
      end

      it { is_expected.to include(*fields, *slack_app_fields) }
      it { is_expected.not_to include(*jira_fields) }

      it 'includes app upgrade URL' do
        stub_application_setting(slack_app_id: 'MOCK_APP_ID')

        expect(subject[:upgrade_slack_url]).to start_with(
          [
            Integrations::SlackInstallation::BaseService::SLACK_AUTHORIZE_URL,
            '?client_id=MOCK_APP_ID',
            "&redirect_uri=#{CGI.escape(redirect_url)}"
          ].join
        )
      end

      it 'includes the flag to upgrade Slack app, set to true' do
        expect(subject[:should_upgrade_slack]).to eq 'true'
      end

      context 'when the integration includes all necessary scopes' do
        let(:integration) { create(:gitlab_slack_application_integration, :all_features_supported, project: project) }

        it 'includes the flag to upgrade Slack app, set to false' do
          expect(subject[:should_upgrade_slack]).to eq 'false'
        end
      end
    end

    context 'with Jenkins integration' do
      let(:integration) { build(:jenkins_integration) }

      it { is_expected.to include(*fields) }
      it { is_expected.not_to include(*jira_fields) }
      it { is_expected.not_to include(*slack_app_fields) }

      specify do
        expect(subject[:reset_path]).to eq(helper.scoped_reset_integration_path(integration))
      end

      specify do
        expect(subject[:redirect_to]).to eq('/services')
      end
    end

    context 'with Jira integration' do
      let(:integration) { build(:jira_integration) }

      it { is_expected.to include(*fields, *jira_fields) }
      it { is_expected.not_to include(*slack_app_fields) }
    end
  end

  describe '#integration_overrides_data' do
    let(:integration) { build_stubbed(:jira_integration) }
    let(:fields) do
      [
        edit_path: edit_admin_application_settings_integration_path(integration),
        overrides_path: overrides_admin_application_settings_integration_path(integration, format: :json)
      ]
    end

    subject { helper.integration_overrides_data(integration) }

    it { is_expected.to include(*fields) }
  end

  describe '#serialize_integration' do
    subject { helper.send(:serialize_integration, integration) }

    let(:integration) { build(:jenkins_integration) }

    it 'serializes the integration' do
      is_expected.to match(a_hash_including(
        id: nil,
        active: true,
        configured: false,
        title: 'Jenkins',
        description: _('Run CI/CD pipelines with Jenkins.'),
        updated_at: nil,
        edit_path: '/admin/application_settings/integrations/jenkins/edit',
        name: 'jenkins',
        icon: nil
      ))
    end
  end

  describe '#scoped_reset_integration_path' do
    let(:integration) { build_stubbed(:jira_integration) }
    let(:group) { nil }

    subject { helper.scoped_reset_integration_path(integration, group: group) }

    context 'when no group is present' do
      it 'returns instance-level path' do
        is_expected.to eq(reset_admin_application_settings_integration_path(integration))
      end
    end

    context 'when group is present' do
      let(:group) { build_stubbed(:group) }

      it 'returns group-level path' do
        is_expected.to eq(reset_group_settings_integration_path(group, integration))
      end
    end

    context 'when a new integration is not persisted' do
      let_it_be(:integration) { build(:jira_integration) }

      it 'returns an empty string' do
        is_expected.to eq('')
      end
    end
  end

  describe '#add_to_slack_link' do
    subject(:slack_link) { helper.add_to_slack_link(project, 'A12345') }

    let(:query) { Rack::Utils.parse_query(URI.parse(slack_link).query) }

    before do
      allow(helper).to receive(:form_authenticity_token).and_return('a token')
    end

    it 'returns the endpoint URL with all needed params' do
      expect(helper).to receive(:slack_auth_project_settings_slack_url).and_return('http://redirect')
      expect(slack_link).to include('&state=a%20token')
      expect(slack_link).to start_with(Integrations::SlackInstallation::BaseService::SLACK_AUTHORIZE_URL)

      expect(query).to include(
        'scope' => 'commands,chat:write,chat:write.public',
        'client_id' => 'A12345',
        'redirect_uri' => 'http://redirect',
        'state' => 'a token'
      )
    end

    context 'when passed a group' do
      subject(:slack_link) { helper.add_to_slack_link(build_stubbed(:group), 'A12345') }

      it 'returns the endpoint URL a redirect-uri for the group' do
        expect(helper).to receive(:slack_auth_group_settings_slack_url).and_return('http://group-redirect')
        expect(query).to include('redirect_uri' => 'http://group-redirect')
      end
    end

    context 'when passed nil' do
      subject(:slack_link) { helper.add_to_slack_link(nil, 'A12345') }

      it 'returns the endpoint URL a redirect-uri for the instance' do
        expect(helper).to receive(:slack_auth_admin_application_settings_slack_url).and_return('http://instance-redirect')
        expect(query).to include('redirect_uri' => 'http://instance-redirect')
      end
    end
  end

  describe '#slack_integration_destroy_path' do
    subject(:destroy_path) { helper.slack_integration_destroy_path(parent) }

    context 'when parent is a project' do
      let(:parent) { project }

      it 'returns the correct path' do
        expect(helper).to receive(:project_settings_slack_path).and_return('http://project-redirect')
        expect(destroy_path).to eq('http://project-redirect')
      end
    end

    context 'when parent is a group' do
      let(:parent) { build_stubbed(:group) }

      it 'returns the endpoint URL a redirect-uri for the group' do
        expect(helper).to receive(:group_settings_slack_path).and_return('http://group-redirect')
        expect(destroy_path).to eq('http://group-redirect')
      end
    end

    context 'when parent is nil' do
      let(:parent) { nil }

      it 'returns the endpoint URL a redirect-uri for the instance' do
        expect(helper).to receive(:admin_application_settings_slack_path).and_return('http://instance-redirect')
        expect(destroy_path).to eq('http://instance-redirect')
      end
    end
  end

  describe '#gitlab_slack_application_data' do
    let_it_be(:projects) { create_list(:project, 3) }

    def relation
      Project.id_in(projects.pluck(:id)).inc_routes
    end

    before do
      allow(helper).to receive(:current_user).and_return(build(:user))
      allow(helper).to receive(:new_session_path).and_return('http://session-path')
    end

    it 'includes the required keys' do
      additions = helper.gitlab_slack_application_data(relation)

      expect(additions.keys).to include(
        :projects,
        :sign_in_path,
        :is_signed_in,
        :slack_link_path,
        :gitlab_logo_path,
        :slack_logo_path
      )
    end

    it 'does not suffer from N+1 performance issues' do
      baseline = ActiveRecord::QueryRecorder.new { helper.gitlab_slack_application_data(relation.limit(1)) }

      expect do
        helper.gitlab_slack_application_data(relation)
      end.not_to exceed_query_limit(baseline)
    end

    it 'serializes nil projects without error' do
      expect(helper.gitlab_slack_application_data(nil)).to include(projects: '[]')
    end
  end

  describe '#integration_issue_type' do
    using RSpec::Parameterized::TableSyntax
    let_it_be(:issue) { create(:issue) }

    where(:issue_type, :expected_i18n_issue_type) do
      "issue"           | _('Issue')
      "incident"        | _('Incident')
      "test_case"       | _('Test case')
      "requirement"     | _('Requirement')
      "task"            | _('Task')
      "ticket"          | _('Service Desk Ticket')
    end

    with_them do
      before do
        issue.assign_attributes(work_item_type: WorkItems::Type.default_by_type(issue_type))
        issue.save!(validate: false)
      end

      it "return the correct i18n issue type" do
        expect(described_class.integration_issue_type(issue.work_item_type.base_type)).to eq(expected_i18n_issue_type)
      end
    end

    it "only consider these enumeration values are valid" do
      expected_valid_types = %w[issue incident test_case requirement task objective key_result epic ticket]
      expect(WorkItems::Type.base_types.keys).to contain_exactly(*expected_valid_types)
    end
  end

  describe '#integration_todo_target_type' do
    using RSpec::Parameterized::TableSyntax
    let!(:todo) { create(:todo, commit_id: '123') }

    where(:target_type, :expected_i18n_target_type) do
      "Commit"                      | _("Commit")
      "Issue"                       | _("Issue")
      "MergeRequest"                | _("Merge Request")
      'Epic'                        | _('Epic')
      DesignManagement::Design.name | _('design')
      AlertManagement::Alert.name   | _('alert')
    end

    with_them do
      before do
        todo.update!(target_type: target_type)
      end

      it { expect(described_class.integration_todo_target_type(todo.target_type)).to eq(expected_i18n_target_type) }
    end
  end

  describe '#integration_webhook_event_human_name' do
    where(:event, :mapping) do
      :repository_update_events | 'Repository update events'
      :push_events | 'Push events'
      :tag_push_events | 'Tag push events'
      :note_events | 'Comments'
      :confidential_note_events | 'Confidential comments'
      :issues_events | 'Issues events'
      :confidential_issues_events | 'Confidential issues events'
      :subgroup_events | 'Subgroup events'
      :member_events | 'Member events'
      :merge_requests_events | 'Merge request events'
      :job_events | 'Job events'
      :pipeline_events | 'Pipeline events'
      :wiki_page_events | 'Wiki page events'
      :deployment_events | 'Deployment events'
      :feature_flag_events | 'Feature flag events'
      :releases_events | 'Releases events'
      :resource_access_token_events | 'Project or group access token events'
      :vulnerability_events | 'Vulnerability events'
    end

    with_them do
      it 'maps to a human name' do
        expect(described_class.integration_webhook_event_human_name(event)).to eq(mapping)
      end
    end
  end
end
