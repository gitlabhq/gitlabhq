# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestSavedView'], feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:saved_view) { create(:merge_request_saved_view, user: current_user) }

  specify { expect(described_class.graphql_name).to eq('MergeRequestSavedView') }

  specify { expect(described_class).to require_graphql_authorizations(:read_saved_view) }

  it 'has the expected fields' do
    expect(described_class).to include_graphql_fields('id', 'name', 'filters', 'user_permissions')
  end

  it 'has the expected id field type' do
    expect(described_class.fields['id'].type).to eq(
      Types::GlobalIDType[::MergeRequests::SavedView].to_non_null_type
    )
  end

  it 'has the expected user_permissions field type' do
    expect(described_class.fields['userPermissions'].type).to eq(
      Types::PermissionTypes::MergeRequests::SavedView.to_non_null_type
    )
  end

  describe '#filters' do
    it 'camelizes stored filter keys, including nested not keys' do
      view_with_filters = create(:merge_request_saved_view, user: current_user, filters: {
        'state' => 'opened',
        'assignee_usernames' => ['root'],
        'not' => { 'author_username' => 'x' }
      })

      expect(resolve_field(:filters, view_with_filters, current_user: current_user)).to eq({
        'state' => 'opened',
        'assigneeUsernames' => ['root'],
        'not' => { 'authorUsername' => 'x' }
      })
    end

    it 'returns an empty hash when no filters are stored' do
      expect(resolve_field(:filters, saved_view, current_user: current_user)).to eq({})
    end
  end
end
