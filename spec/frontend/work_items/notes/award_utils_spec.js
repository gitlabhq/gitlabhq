import { getMutation, optimisticAwardUpdate } from '~/work_items/notes/award_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import mockApollo from 'helpers/mock_apollo_helper';
import { __ } from '~/locale';
import groupWorkItemNotesByIidQuery from '~/work_items/graphql/notes/group_work_item_notes_by_iid.query.graphql';
import workItemNotesByIidQuery from '~/work_items/graphql/notes/work_item_notes_by_iid.query.graphql';
import addAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_add_award_emoji.mutation.graphql';
import removeAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_remove_award_emoji.mutation.graphql';
import {
  mockWorkItemNotesResponseWithComments,
  mockAwardEmojiThumbsUp,
  mockAwardEmojiThumbsDown,
} from '../mock_data';

function getWorkItem(data) {
  return data.workspace.workItems.nodes[0];
}
function getFirstNote(workItem) {
  return workItem.widgets.find((w) => w.type === 'NOTES').discussions.nodes[0].notes.nodes[0];
}

describe('Work item note award utils', () => {
  const workItem = getWorkItem(mockWorkItemNotesResponseWithComments.data);
  const firstNote = getFirstNote(workItem);
  const fullPath = 'test-project-path';
  const workItemIid = workItem.iid;
  const currentUserId = getIdFromGraphQLId(mockAwardEmojiThumbsDown.user.id);

  beforeEach(() => {
    window.gon = { current_user_id: currentUserId };
  });

  describe('getMutation', () => {
    it('returns remove mutation when user has already awarded award', () => {
      const note = firstNote;
      const { name } = mockAwardEmojiThumbsDown;

      expect(getMutation({ note, name })).toEqual({
        mutation: removeAwardEmojiMutation,
        mutationName: 'awardEmojiRemove',
        errorMessage: __('Failed to remove emoji. Please try again'),
      });
    });

    it('returns remove mutation when user has not already awarded award', () => {
      const note = {};
      const { name } = mockAwardEmojiThumbsUp;

      expect(getMutation({ note, name })).toEqual({
        mutation: addAwardEmojiMutation,
        mutationName: 'awardEmojiAdd',
        errorMessage: __('Failed to add emoji. Please try again'),
      });
    });
  });

  describe('optimisticAwardUpdate', () => {
    let apolloProvider;
    beforeEach(() => {
      apolloProvider = mockApollo();

      apolloProvider.clients.defaultClient.writeQuery({
        query: workItemNotesByIidQuery,
        variables: { fullPath, iid: workItemIid },
        ...mockWorkItemNotesResponseWithComments,
      });
    });

    it('adds new emoji to cache', () => {
      const note = firstNote;
      const { name } = mockAwardEmojiThumbsUp;

      const updateFn = optimisticAwardUpdate({ note, name, fullPath, workItemIid });

      updateFn(apolloProvider.clients.defaultClient.cache);

      const updatedResult = apolloProvider.clients.defaultClient.readQuery({
        query: workItemNotesByIidQuery,
        variables: { fullPath, iid: workItemIid },
      });

      const updatedWorkItem = getWorkItem(updatedResult);
      const updatedNote = getFirstNote(updatedWorkItem);

      expect(updatedNote.awardEmoji.nodes).toEqual([
        mockAwardEmojiThumbsDown,
        mockAwardEmojiThumbsUp,
      ]);
    });

    it('removes existing emoji from cache', () => {
      const note = firstNote;
      const { name } = mockAwardEmojiThumbsDown;

      const updateFn = optimisticAwardUpdate({ note, name, fullPath, workItemIid });

      updateFn(apolloProvider.clients.defaultClient.cache);

      const updatedResult = apolloProvider.clients.defaultClient.readQuery({
        query: workItemNotesByIidQuery,
        variables: { fullPath, iid: workItemIid },
      });

      const updatedWorkItem = getWorkItem(updatedResult);
      const updatedNote = getFirstNote(updatedWorkItem);

      expect(updatedNote.awardEmoji.nodes).toEqual([]);
    });

    it.each`
      description                                      | isGroup  | query
      ${'calls project query when in project context'} | ${false} | ${workItemNotesByIidQuery}
      ${'calls group query when in group context'}     | ${true}  | ${groupWorkItemNotesByIidQuery}
    `('$description', ({ isGroup, query }) => {
      const note = firstNote;
      const { name } = mockAwardEmojiThumbsUp;
      const cacheSpy = { updateQuery: jest.fn() };

      optimisticAwardUpdate({ note, name, fullPath, isGroup, workItemIid })(cacheSpy);

      expect(cacheSpy.updateQuery).toHaveBeenCalledWith(
        { query, variables: { fullPath, iid: workItemIid } },
        expect.any(Function),
      );
    });
  });
});
