# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IntegrationsHelper do
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
        :show_active,
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

    subject { helper.integration_form_data(integration) }

    context 'with Slack integration' do
      let(:integration) { build(:integrations_slack) }

      it { is_expected.to include(*fields) }
      it { is_expected.not_to include(*jira_fields) }

      specify do
        expect(subject[:reset_path]).to eq(helper.scoped_reset_integration_path(integration))
      end

      specify do
        expect(subject[:redirect_to]).to eq('/services')
      end
    end

    context 'Jira service' do
      let(:integration) { build(:jira_integration) }

      it { is_expected.to include(*fields, *jira_fields) }
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

  describe '#integration_issue_type' do
    using RSpec::Parameterized::TableSyntax
    let_it_be(:issue) { create(:issue) }

    where(:issue_type, :expected_i18n_issue_type) do
      "issue"           | _('Issue')
      "incident"        | _('Incident')
      "test_case"       | _('Test case')
      "requirement"     | _('Requirement')
      "task"            | _('Task')
    end

    with_them do
      before do
        issue.assign_attributes(issue_type: issue_type, work_item_type: WorkItems::Type.default_by_type(issue_type))
        issue.save!(validate: false)
      end

      it "return the correct i18n issue type" do
        expect(described_class.integration_issue_type(issue.work_item_type.base_type)).to eq(expected_i18n_issue_type)
      end
    end

    it "only consider these enumeration values are valid" do
      expected_valid_types = %w[issue incident test_case requirement task objective key_result]
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
end
