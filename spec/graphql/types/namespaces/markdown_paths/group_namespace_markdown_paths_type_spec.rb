# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::MarkdownPaths::GroupNamespaceMarkdownPathsType, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

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
    context 'with valid autocomplete types' do
      where(:autocomplete_type, :expected_path) do
        'members' | lazy { "/groups/#{group.full_path}/-/autocomplete_sources/members" }
        'issues' | lazy { "/groups/#{group.full_path}/-/autocomplete_sources/issues" }
        'merge_requests' | lazy { "/groups/#{group.full_path}/-/autocomplete_sources/merge_requests" }
        'labels' | lazy { "/groups/#{group.full_path}/-/autocomplete_sources/labels" }
        'milestones' | lazy { "/groups/#{group.full_path}/-/autocomplete_sources/milestones" }
        'commands' | lazy { "/groups/#{group.full_path}/-/autocomplete_sources/commands" }
      end

      with_them do
        context 'without additional params' do
          it 'returns the autocomplete path with type param' do
            result = resolve_field(:autocomplete_sources_path, group, args: { autocomplete_type: autocomplete_type },
              current_user: user)
            expect(result).to eq("#{expected_path}?type=WorkItem")
          end
        end

        context 'with iid' do
          it 'returns the autocomplete path with type_id param' do
            result = resolve_field(:autocomplete_sources_path, group,
              args: { autocomplete_type: autocomplete_type, iid: '456' }, current_user: user)
            expect(result).to eq("#{expected_path}?type=WorkItem&type_id=456")
          end
        end

        context 'with new-work-item-iid work item (iid: "new-work-item-iid" and work_item_type_id)' do
          it 'returns the autocomplete path with work_item_type_id param' do
            gid = 'gid://gitlab/WorkItems::Type/789'
            result = resolve_field(:autocomplete_sources_path, group,
              args: {
                autocomplete_type: autocomplete_type,
                iid: 'new-work-item-iid',
                work_item_type_id: gid
              }, current_user: user)
            expect(result).to eq("#{expected_path}?type=WorkItem&work_item_type_id=789")
          end
        end
      end
    end

    context 'with invalid autocomplete type' do
      it 'returns nil' do
        result = resolve_field(:autocomplete_sources_path, group, args: { autocomplete_type: 'invalid' },
          current_user: user)
        expect(result).to be_nil
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
