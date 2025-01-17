# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::WorkItem do
  it do
    expected_permissions = [
      :read_work_item, :update_work_item, :delete_work_item, :admin_work_item,
      :admin_parent_link, :set_work_item_metadata, :create_note, :admin_work_item_link, :mark_note_as_internal,
      :report_spam
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
