import { __ } from '~/locale';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  updateCacheAfterAddingAwardEmojiToNote,
  updateCacheAfterRemovingAwardEmojiFromNote,
} from '~/work_items/graphql/cache_utils';
import workItemNotesByIidQuery from '../graphql/notes/work_item_notes_by_iid.query.graphql';
import addAwardEmojiMutation from '../graphql/notes/work_item_note_add_award_emoji.mutation.graphql';
import removeAwardEmojiMutation from '../graphql/notes/work_item_note_remove_award_emoji.mutation.graphql';

function awardedByCurrentUser(note) {
  return (note.awardEmoji?.nodes ?? [])
    .filter((award) => {
      return getIdFromGraphQLId(award.user.id) === window.gon.current_user_id;
    })
    .map((award) => award.name);
}

export function getMutation({ note, name }) {
  if (awardedByCurrentUser(note).includes(name)) {
    return {
      mutation: removeAwardEmojiMutation,
      mutationName: 'awardEmojiRemove',
      errorMessage: __('Failed to remove emoji. Please try again'),
    };
  }
  return {
    mutation: addAwardEmojiMutation,
    mutationName: 'awardEmojiAdd',
    errorMessage: __('Failed to add emoji. Please try again'),
  };
}

export function optimisticAwardUpdate({ note, name, fullPath, workItemIid }) {
  const { mutation } = getMutation({ note, name });

  const currentUserId = window.gon.current_user_id;

  return (store) => {
    store.updateQuery(
      {
        query: workItemNotesByIidQuery,
        variables: { fullPath, iid: workItemIid },
      },
      (sourceData) => {
        const updatedNote = {
          id: note.id,
          awardEmoji: {
            __typename: 'AwardEmoji',
            name,
            user: {
              __typename: 'UserCore',
              id: convertToGraphQLId(TYPENAME_USER, currentUserId),
              name: null,
            },
          },
        };

        if (mutation === removeAwardEmojiMutation) {
          return updateCacheAfterRemovingAwardEmojiFromNote(sourceData, updatedNote);
        }
        return updateCacheAfterAddingAwardEmojiToNote(sourceData, updatedNote);
      },
    );
  };
}
