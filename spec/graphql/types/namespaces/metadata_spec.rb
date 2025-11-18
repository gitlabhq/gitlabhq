# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Namespaces::Metadata, feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe '.resolve_type' do
    it 'resolves GroupNamespaceMetadata for Group' do
      expect(described_class.resolve_type(group, {}))
        .to eq(Types::Namespaces::Metadata::GroupNamespaceMetadataType)
    end

    it 'resolves ProjectNamespaceMetadata for ProjectNamespace' do
      expect(described_class.resolve_type(project.project_namespace, {}))
        .to eq(Types::Namespaces::Metadata::ProjectNamespaceMetadataType)
    end

    it 'resolves UserNamespaceMetadata for UserNamespace' do
      user_namespace = create(:user_namespace)
      expect(described_class.resolve_type(user_namespace, {}))
        .to eq(Types::Namespaces::Metadata::UserNamespaceMetadataType)
    end
  end

  describe 'field exposure' do
    it 'exposes all expected fields' do
      expected_fields = %i[
        timeTrackingLimitToHours
        initialSort
        isIssueRepositioningDisabled
        showNewWorkItem
        maxAttachmentSize
        groupId
      ]

      expected_fields.each do |field|
        expect(described_class).to have_graphql_field(field)
      end
    end
  end
end
