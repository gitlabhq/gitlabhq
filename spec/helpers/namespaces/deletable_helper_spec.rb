# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::DeletableHelper, feature_category: :groups_and_projects do
  include SafeFormatHelper
  include NumbersHelper

  shared_examples 'raise error with unsupported namespace type' do
    context 'when namespace is unsupported' do
      let(:namespace) { build_stubbed(:organization) }

      it 'raises an error' do
        expect { message }.to raise_error(RuntimeError, "Unsupported namespace type: #{namespace.class.name}")
      end
    end
  end

  describe '#permanent_deletion_date_formatted', :freeze_time do
    before do
      stub_application_setting(deletion_adjourned_period: 5)
    end

    context 'when namespace does not respond to :self_deletion_scheduled_deletion_created_on' do
      let(:namespace) { instance_double(Namespace) }

      it 'returns false' do
        expect(permanent_deletion_date_formatted(namespace)).to be_nil
      end
    end

    context 'when namespace responds to :self_deletion_scheduled_deletion_created_on' do
      context 'when namespace.self_deletion_scheduled_deletion_created_on returns nil' do
        let(:namespace) { instance_double(Namespace, self_deletion_scheduled_deletion_created_on: nil) }

        it 'returns nil' do
          expect(permanent_deletion_date_formatted(namespace)).to be_nil
        end
      end

      context 'when namespace.self_deletion_scheduled_deletion_created_on returns a date' do
        let(:namespace) { instance_double(Namespace, self_deletion_scheduled_deletion_created_on: Date.yesterday) }

        it 'returns the date formatted' do
          expect(permanent_deletion_date_formatted(namespace)).to eq(4.days.from_now.strftime('%F'))
        end
      end

      context 'when date is passed as argument' do
        it 'returns the date formatted' do
          expect(permanent_deletion_date_formatted(Date.current)).to eq(5.days.from_now.strftime('%F'))
        end
      end

      context 'when no argument is passed' do
        it 'returns the date formatted' do
          expect(permanent_deletion_date_formatted).to eq(5.days.from_now.strftime('%F'))
        end
      end
    end

    context 'when a format is given' do
      it 'returns the date formatted with the given format' do
        expect(permanent_deletion_date_formatted(format: Date::DATE_FORMATS[:medium]))
          .to eq(5.days.from_now.strftime(Date::DATE_FORMATS[:medium]))
      end
    end
  end

  describe '#deletion_in_progress_or_scheduled_in_hierarchy_chain?' do
    subject(:message) { helper.deletion_in_progress_or_scheduled_in_hierarchy_chain?(namespace) }

    context 'when namespace does not respond to :deletion_in_progress_or_scheduled_in_hierarchy_chain?' do
      let(:namespace) { build_stubbed(:organization) }

      specify do
        expect(message).to be(false)
      end
    end

    using RSpec::Parameterized::TableSyntax

    where(:namespace_type, :deletion_in_progress_or_scheduled_in_hierarchy_chain) do
      :group             | false
      :project           | false
      :project_namespace | false
      :group             | true
      :project           | true
      :project_namespace | true
    end

    with_them do
      let(:namespace) { build_stubbed(namespace_type) }

      before do
        allow(namespace).to receive_messages(
          deletion_in_progress_or_scheduled_in_hierarchy_chain?: deletion_in_progress_or_scheduled_in_hierarchy_chain
        )
      end

      specify do
        expect(message).to be(deletion_in_progress_or_scheduled_in_hierarchy_chain)
      end
    end
  end

  describe '#self_or_ancestors_deletion_in_progress_or_scheduled_message' do
    subject(:message) { helper.self_or_ancestors_deletion_in_progress_or_scheduled_message(namespace) }

    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength -- We cannot wrap lines when using RSpec::Parameterized::TableSyntax
    where(:namespace_type, :self_deletion_in_progress, :self_deletion_scheduled, :expected_message) do
      :group             | false | false | 'This group will be deleted on <strong>2025-01-22</strong> because its parent group is scheduled for deletion.'
      :project           | false | false | 'This project will be deleted on <strong>2025-01-22</strong> because its parent group is scheduled for deletion.'
      :project_namespace | false | false | 'This project will be deleted on <strong>2025-01-22</strong> because its parent group is scheduled for deletion.'
      :group             | false | true | 'This group and its subgroups and projects are pending deletion, and will be deleted on <strong>2025-02-09</strong>.'
      :project           | false | true | 'This project is pending deletion, and will be deleted on <strong>2025-02-09</strong>. Repository and other project resources are read-only.'
      :project_namespace | false | true | 'This project is pending deletion, and will be deleted on <strong>2025-02-09</strong>. Repository and other project resources are read-only.'
      :group             | true  | nil  | 'This group and its subgroups are being deleted.'
      :project           | true  | nil  | 'This project is being deleted. Repository and other project resources are read-only.'
      :project_namespace | true  | nil  | 'This project is being deleted. Repository and other project resources are read-only.'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      let(:namespace) { build_stubbed(namespace_type) }
      let(:ancestor_namespace) { build_stubbed(:namespace) }

      before do
        stub_application_setting(deletion_adjourned_period: 7)
        allow(namespace).to receive_messages(
          self_deletion_in_progress?: self_deletion_in_progress,
          self_deletion_scheduled?: self_deletion_scheduled,
          first_scheduled_for_deletion_in_hierarchy_chain: ancestor_namespace
        )
        allow(namespace)
          .to receive(:self_deletion_scheduled_deletion_created_on)
          .and_return(Date.parse('2025-02-02'))
        allow(ancestor_namespace)
          .to receive(:self_deletion_scheduled_deletion_created_on)
          .and_return(Date.parse('2025-01-15'))
      end

      specify do
        expect(message).to eq(expected_message)
      end
    end
  end

  describe '#delete_delayed_namespace_message' do
    let(:deletion_adjourned_period) { ::Gitlab::CurrentSettings.deletion_adjourned_period }

    subject(:message) { helper.delete_delayed_namespace_message(namespace) }

    context 'when namespace is a Group' do
      let(:namespace) { build_stubbed(:group) }

      specify do
        expect(message).to eq "This action will place this group, " \
          "including its subgroups and projects, in a pending deletion state for #{deletion_adjourned_period} days, " \
          "and delete it permanently on <strong>#{helper.permanent_deletion_date_formatted}</strong>."
      end
    end

    %i[project project_namespace].each do |entity|
      context "when namespace is a #{entity}" do
        let(:namespace) { build_stubbed(entity) }

        specify do
          expect(message).to eq "This action will place this project, " \
            "including all its resources, in a pending deletion state for #{deletion_adjourned_period} days, " \
            "and delete it permanently on <strong>#{helper.permanent_deletion_date_formatted}</strong>."
        end
      end
    end

    it_behaves_like 'raise error with unsupported namespace type'
  end

  describe '#delete_immediately_namespace_scheduled_for_deletion_message' do
    let(:marked_for_deletion) { Date.parse('2024-01-01') }

    subject(:message) { helper.delete_immediately_namespace_scheduled_for_deletion_message(namespace) }

    before do
      allow(namespace).to receive(:marked_for_deletion_on).and_return(marked_for_deletion)
    end

    context 'when namespace is a Group' do
      let(:namespace) { build_stubbed(:group) }

      specify do
        expect(message).to eq "This group is scheduled for deletion on " \
          "<strong>#{helper.permanent_deletion_date_formatted(namespace)}</strong>. " \
          "This action will permanently delete this group, including its subgroups and projects, " \
          "<strong>immediately</strong>. This action cannot be undone."
      end
    end

    %i[project project_namespace].each do |entity|
      context "when namespace is a #{entity}" do
        let(:namespace) { build_stubbed(entity) }

        specify do
          expect(message).to eq "This project is scheduled for deletion on " \
            "<strong>#{helper.permanent_deletion_date_formatted(namespace)}</strong>. " \
            "This action will permanently delete this project, including all its resources, " \
            "<strong>immediately</strong>. This action cannot be undone."
        end
      end
    end

    it_behaves_like 'raise error with unsupported namespace type'
  end

  describe '#group_confirm_modal_data' do
    using RSpec::Parameterized::TableSyntax
    let_it_be(:group) { build_stubbed(:group, path: "foo") }

    fake_form_id = "fake_form_id"
    where(:prevent_delete_response, :is_button_disabled, :form_value_id,
      :permanently_remove, :button_text, :has_security_policy_project) do
      true  | "true"  | fake_form_id | true | nil | false
      false | "false" | fake_form_id | true | nil | false
    end

    with_them do
      it "returns expected parameters" do
        allow(group).to receive_messages(linked_to_subscription?: prevent_delete_response)

        expected = helper.group_confirm_modal_data(group: group, remove_form_id: form_value_id,
          button_text: button_text, has_security_policy_project: has_security_policy_project,
          permanently_remove: permanently_remove)
        expect(expected).to eq({
          button_text: button_text.nil? ? "Delete" : button_text,
          confirm_danger_message: confirm_remove_group_message(group, permanently_remove),
          remove_form_id: form_value_id,
          phrase: group.full_path,
          button_testid: "remove-group-button",
          disabled: is_button_disabled,
          html_confirmation_message: 'true'
        })
      end
    end
  end

  describe '#confirm_remove_group_message' do
    let_it_be(:group) { build_stubbed(:group) }
    let(:delayed_deletion_message) do
      "The contents of this group, its subgroups and projects will be permanently deleted after"
    end

    let(:permanent_deletion_message) do
      [
        "You are about to delete the group #{group.name}",
        "After you delete a group, you <strong>cannot</strong> restore it or its components."
      ]
    end

    let(:permanently_remove) { false }
    let(:additional_items_deleted_start) { '<span> This action will also delete:</span><ul>' }

    subject(:message) { helper.confirm_remove_group_message(group, permanently_remove) }

    shared_examples 'permanent deletion message' do
      it 'returns the message related to permanent deletion' do
        expect(message).to include(*permanent_deletion_message)
        expect(message).not_to include(delayed_deletion_message)
      end
    end

    shared_examples 'delayed deletion message' do
      it 'returns the message related to delayed deletion' do
        expect(message).to include(delayed_deletion_message)
        expect(message).not_to include(*permanent_deletion_message)
      end
    end

    it_behaves_like 'delayed deletion message'

    context 'when group is marked for deletion' do
      before do
        allow(group).to receive_messages(self_deletion_scheduled?: true)
      end

      it_behaves_like 'permanent deletion message'
    end

    context 'when permanently_remove is true' do
      let(:permanently_remove) { true }

      it_behaves_like 'permanent deletion message'

      describe 'additional items deleted' do
        using RSpec::Parameterized::TableSyntax

        where(:subgroups_count, :non_archived_projects, :archived_projects, :expected_additional_items) do
          1 | 1 | 1 | '<li>1 subgroup</li><li>1 active project</li><li>1 archived project</li></ul>'
          2 | 5 | 3 | '<li>2 subgroups</li><li>5 active projects</li><li>3 archived projects</li></ul>'
          101 | 101 | 101 | '<li>100+ subgroups</li><li>100+ active projects</li><li>100+ archived projects</li></ul>'
          2 | 0 | 0 | '<li>2 subgroups</li></ul>'
          2 | 0 | 0 | '<li>2 subgroups</li></ul>'
          0 | 5 | 0 | '<li>5 active projects</li></ul>'
          0 | 0 | 5 | '<li>5 archived projects</li></ul>'
        end

        with_them do
          before do
            allow(group).to receive_message_chain(:children, :page, :total_count_with_limit)
              .and_return(subgroups_count)
            allow(group).to receive_message_chain(:all_projects, :non_archived, :page, :total_count_with_limit)
              .and_return(non_archived_projects)
            allow(group).to receive_message_chain(:all_projects, :archived, :page, :total_count_with_limit)
              .and_return(archived_projects)
          end

          specify do
            expect(message).to include(additional_items_deleted_start + expected_additional_items)
          end
        end

        context 'when no sub-resources exist' do
          it 'does not return a list when there are no subgroups or projects' do
            expect(message).not_to include(additional_items_deleted_start)
          end
        end
      end
    end
  end

  describe '#project_delete_delayed_button_data', time_travel_to: '2025-02-02' do
    let(:project) { build(:project) }
    let(:base_button_data) do
      {
        button_text: 'Delete',
        form_path: project_path(project),
        confirm_phrase: project.path_with_namespace,
        name_with_namespace: project.name_with_namespace,
        is_fork: 'false',
        issues_count: '0',
        merge_requests_count: '0',
        forks_count: '0',
        stars_count: '0',
        permanent_deletion_date: '2025-02-09',
        marked_for_deletion: 'false'
      }
    end

    subject(:data) { helper.project_delete_delayed_button_data(project) }

    before do
      stub_application_setting(deletion_adjourned_period: 7)
    end

    it 'returns expected hash' do
      expect(data).to match(base_button_data)
    end
  end

  describe '#project_delete_immediately_button_data', time_travel_to: '2025-02-02' do
    let(:project) { build(:project) }
    let(:base_button_data) do
      {
        button_text: 'Delete immediately',
        form_path: project_path(project, permanently_delete: true),
        confirm_phrase: project.path_with_namespace,
        name_with_namespace: project.name_with_namespace,
        is_fork: 'false',
        issues_count: '0',
        merge_requests_count: '0',
        forks_count: '0',
        stars_count: '0',
        permanent_deletion_date: '2025-02-09',
        marked_for_deletion: 'false'
      }
    end

    subject(:data) { helper.project_delete_immediately_button_data(project) }

    before do
      stub_application_setting(deletion_adjourned_period: 7)
    end

    it 'returns expected hash' do
      expect(data).to match(base_button_data)
    end
  end

  describe '#restore_namespace_title' do
    subject(:message) { helper.restore_namespace_title(namespace) }

    context 'when namespace is a Group' do
      let(:namespace) { build_stubbed(:group) }

      specify do
        expect(message).to eq 'Restore group'
      end
    end

    %i[project project_namespace].each do |entity|
      context "when namespace is a #{entity}" do
        let(:namespace) { build_stubbed(entity) }

        specify do
          expect(message).to eq 'Restore project'
        end
      end
    end

    it_behaves_like 'raise error with unsupported namespace type'
  end

  describe '#restore_namespace_path' do
    subject(:message) { helper.restore_namespace_path(namespace) }

    context 'when namespace is a Group' do
      let(:namespace) { build_stubbed(:group) }

      specify do
        expect(message).to eq group_restore_path(namespace)
      end
    end

    %i[project].each do |entity|
      context "when namespace is a #{entity}" do
        let(:namespace) { build_stubbed(entity) }

        specify do
          expect(message).to eq namespace_project_restore_path(namespace.parent, namespace)
        end
      end
    end

    it_behaves_like 'raise error with unsupported namespace type'
  end

  describe '#restore_namespace_scheduled_for_deletion_message' do
    subject(:message) { helper.restore_namespace_scheduled_for_deletion_message(namespace) }

    before do
      stub_application_setting(deletion_adjourned_period: 7)
      allow(namespace).to receive(:self_deletion_scheduled_deletion_created_on).and_return(Date.parse('2025-02-02'))
    end

    context 'when namespace is a Group' do
      let(:namespace) { build_stubbed(:group) }

      specify do
        expect(message).to eq "This group has been scheduled for deletion on <strong>2025-02-09</strong>. " \
          "To cancel the scheduled deletion, you can restore this group, including all its resources."
      end
    end

    %i[project project_namespace].each do |entity|
      context "when namespace is a #{entity}" do
        let(:namespace) { build_stubbed(entity) }

        specify do
          expect(message).to eq "This project has been scheduled for deletion on <strong>2025-02-09</strong>. " \
            "To cancel the scheduled deletion, you can restore this project, including all its resources."
        end
      end
    end

    it_behaves_like 'raise error with unsupported namespace type'
  end
end
