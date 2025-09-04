# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::MarkdownPaths::GroupNamespaceMarkdownPathsType, feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :nested, :public, developers: user) }

  describe '#uploads_path' do
    it 'returns the group uploads path' do
      expect(resolve_field(:uploads_path, group, current_user: user)).to eq("/groups/#{group.full_path}/-/uploads")
    end
  end

  describe '#markdown_preview_path' do
    context 'without iid' do
      it 'returns the basic preview markdown path' do
        expect(resolve_field(:markdown_preview_path, group,
          current_user: user)).to eq("/groups/#{group.full_path}/-/preview_markdown?target_type=WorkItem")
      end
    end

    context 'with iid' do
      it 'returns the preview markdown path with query params' do
        expect(resolve_field(:markdown_preview_path, group, args: { iid: '123' }, current_user: user))
          .to eq("/groups/#{group.full_path}/-/preview_markdown?target_id=123&target_type=WorkItem")
      end
    end
  end

  describe '#autocomplete_sources_path' do
    context 'without additional params' do
      it 'returns all autocomplete paths with type param' do
        result = resolve_field(:autocomplete_sources_path, group, current_user: user)

        expect(result).to be_a(Hash)
        expect(result).to include(
          members: "/groups/#{group.full_path}/-/autocomplete_sources/members?type=WorkItem",
          issues: "/groups/#{group.full_path}/-/autocomplete_sources/issues?type=WorkItem",
          mergeRequests: "/groups/#{group.full_path}/-/autocomplete_sources/merge_requests?type=WorkItem",
          labels: "/groups/#{group.full_path}/-/autocomplete_sources/labels?type=WorkItem",
          milestones: "/groups/#{group.full_path}/-/autocomplete_sources/milestones?type=WorkItem",
          commands: "/groups/#{group.full_path}/-/autocomplete_sources/commands?type=WorkItem"
        )
      end
    end

    context 'with iid' do
      it 'returns all autocomplete paths with type_id param' do
        result = resolve_field(:autocomplete_sources_path, group, args: { iid: '456' }, current_user: user)

        expect(result).to be_a(Hash)
        expect(result).to include(
          members: "/groups/#{group.full_path}/-/autocomplete_sources/members?type=WorkItem&type_id=456",
          issues: "/groups/#{group.full_path}/-/autocomplete_sources/issues?type=WorkItem&type_id=456",
          mergeRequests: "/groups/#{group.full_path}/-/autocomplete_sources/merge_requests?type=WorkItem&type_id=456",
          labels: "/groups/#{group.full_path}/-/autocomplete_sources/labels?type=WorkItem&type_id=456",
          milestones: "/groups/#{group.full_path}/-/autocomplete_sources/milestones?type=WorkItem&type_id=456",
          commands: "/groups/#{group.full_path}/-/autocomplete_sources/commands?type=WorkItem&type_id=456"
        )
      end
    end

    context 'with new-work-item-iid and work_item_type_id' do
      it 'returns all autocomplete paths with work_item_type_id param' do
        gid = 'gid://gitlab/WorkItems::Type/789'
        result = resolve_field(:autocomplete_sources_path, group,
          args: { iid: 'new-work-item-iid', work_item_type_id: gid }, current_user: user)

        expect(result).to be_a(Hash)
        expect(result)
          .to include(
            members: "/groups/#{group.full_path}/-/autocomplete_sources/members?type=WorkItem&work_item_type_id=789",
            issues: "/groups/#{group.full_path}/-/autocomplete_sources/issues?type=WorkItem&work_item_type_id=789",
            mergeRequests: "/groups/#{group.full_path}/-/autocomplete_sources/merge_requests" \
              "?type=WorkItem&work_item_type_id=789",
            labels: "/groups/#{group.full_path}/-/autocomplete_sources/labels?type=WorkItem&work_item_type_id=789",
            milestones: "/groups/#{group.full_path}/-/autocomplete_sources/milestones" \
              "?type=WorkItem&work_item_type_id=789",
            commands: "/groups/#{group.full_path}/-/autocomplete_sources/commands?type=WorkItem&work_item_type_id=789"
          )
      end
    end
  end

  context 'when group is private' do
    let_it_be(:private_group) { create(:group, :nested, :private) }

    context 'when user is not a member' do
      it 'still returns paths' do
        expect(resolve_field(:uploads_path, private_group,
          current_user: user)).to eq("/groups/#{private_group.full_path}/-/uploads")
      end
    end

    context 'when user is a member' do
      before_all do
        private_group.add_developer(user)
      end

      it 'returns paths' do
        expect(resolve_field(:uploads_path, private_group,
          current_user: user)).to eq("/groups/#{private_group.full_path}/-/uploads")
      end
    end
  end
end
