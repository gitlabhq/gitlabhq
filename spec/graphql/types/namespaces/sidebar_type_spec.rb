# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NamespaceSidebar'], feature_category: :navigation do
  include GraphqlHelpers

  let(:fields) do
    %i[open_issues_count open_merge_requests_count open_work_items_count]
  end

  specify { expect(described_class.graphql_name).to eq('NamespaceSidebar') }

  specify { expect(described_class).to have_graphql_fields(fields).at_least }

  describe '#open_work_items_count' do
    let_it_be(:user) { create(:user) }

    before do
      stub_feature_flags(show_work_items_sidebar_count: true)
    end

    context 'when namespace is a Group' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_developer(user)
      end

      it 'delegates to Groups::OpenWorkItemsCountService with fast_timeout' do
        service = instance_double(Groups::OpenWorkItemsCountService, count: 5)
        expect(Groups::OpenWorkItemsCountService)
          .to receive(:new).with(group, user, fast_timeout: true).and_return(service)

        expect(resolve_field(:open_work_items_count, group, current_user: user)).to eq(5)
      end

      it 'returns nil when the query times out' do
        service = instance_double(Groups::OpenWorkItemsCountService)
        allow(Groups::OpenWorkItemsCountService)
          .to receive(:new).with(group, user, fast_timeout: true).and_return(service)
        allow(service).to receive(:count).and_raise(ActiveRecord::QueryCanceled)

        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          an_instance_of(ActiveRecord::QueryCanceled),
          group_id: group.id,
          query: 'group_sidebar_work_items_count'
        )

        expect(resolve_field(:open_work_items_count, group, current_user: user)).to be_nil
      end
    end

    context 'when namespace is a ProjectNamespace' do
      let_it_be(:project) { create(:project) }

      before_all do
        project.add_developer(user)
      end

      it 'delegates to Projects::OpenWorkItemsCountService' do
        service = instance_double(Projects::OpenWorkItemsCountService, count: 3)
        expect(Projects::OpenWorkItemsCountService)
          .to receive(:new).with(project, user).and_return(service)

        expect(resolve_field(:open_work_items_count, project.project_namespace, current_user: user)).to eq(3)
      end
    end

    context 'when namespace is neither a Group nor a ProjectNamespace' do
      let_it_be(:personal_namespace) { create(:namespace) }

      it 'returns nil' do
        expect(resolve_field(:open_work_items_count, personal_namespace, current_user: user)).to be_nil
      end
    end
  end
end
