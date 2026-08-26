# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::MergeRequests::SavedView, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('MergeRequestSavedViewPermissions') }

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(:update_saved_view, :delete_saved_view)
  end
end
