import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import mockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import WorkItemNoteAwardsList from '~/work_items/components/notes/work_item_note_awards_list.vue';
import addAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_add_award_emoji.mutation.graphql';
import removeAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_remove_award_emoji.mutation.graphql';
import workItemNotesByIidQuery from '~/work_items/graphql/notes/work_item_notes_by_iid.query.graphql';
import {
  mockAwardEmojiThumbsUp,
  mockWorkItemNotesResponseWithComments,
} from 'jest/work_items/mock_data';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

Vue.use(VueApollo);

describe('Work Item Note Awards List', () => {
  let wrapper;
  const { workItem } = mockWorkItemNotesResponseWithComments().data.workspace;
  const firstNote = workItem.widgets.find((w) => w.type === 'NOTES').discussions.nodes[0].notes
    .nodes[0];
  const fullPath = 'test-project-path';
  const workItemIid = workItem.iid;
  const currentUserId = getIdFromGraphQLId(mockAwardEmojiThumbsUp.user.id);

  const addAwardEmojiMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      awardEmojiAdd: {
        errors: [],
      },
    },
  });
  const removeAwardEmojiMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      awardEmojiRemove: {
        errors: [],
      },
    },
  });

  const findAwardsList = () => wrapper.findComponent(AwardsList);

  const createComponent = ({
    note = firstNote,
    query = workItemNotesByIidQuery,
    addAwardEmojiMutationHandler = addAwardEmojiMutationSuccessHandler,
    removeAwardEmojiMutationHandler = removeAwardEmojiMutationSuccessHandler,
  } = {}) => {
    const apolloProvider = mockApollo([
      [addAwardEmojiMutation, addAwardEmojiMutationHandler],
      [removeAwardEmojiMutation, removeAwardEmojiMutationHandler],
    ]);

    apolloProvider.clients.defaultClient.writeQuery({
      query,
      variables: { fullPath, iid: workItemIid },
      ...mockWorkItemNotesResponseWithComments(),
    });

    wrapper = shallowMount(WorkItemNoteAwardsList, {
      propsData: {
        fullPath,
        workItemIid,
        note,
        isModal: false,
      },
      apolloProvider,
    });
  };

  beforeEach(() => {
    window.gon.current_user_id = currentUserId;
  });

  describe('when not editing', () => {
    it.each([true, false])('passes emoji permission to awards-list', (hasAwardEmojiPermission) => {
      const note = {
        ...firstNote,
        userPermissions: {
          ...firstNote.userPermissions,
          awardEmoji: hasAwardEmojiPermission,
        },
      };
      createComponent({ note });

      expect(findAwardsList().props('canAwardEmoji')).toBe(hasAwardEmojiPermission);
    });

    it('adds award if not already awarded', async () => {
      createComponent();
      await waitForPromises();

      findAwardsList().vm.$emit('award', EMOJI_THUMBS_UP);

      expect(addAwardEmojiMutationSuccessHandler).toHaveBeenCalledWith({
        awardableId: firstNote.id,
        name: EMOJI_THUMBS_UP,
      });
    });

    it('emits error if awarding emoji fails', async () => {
      createComponent({ addAwardEmojiMutationHandler: jest.fn().mockRejectedValue('oh no') });

      findAwardsList().vm.$emit('award', EMOJI_THUMBS_UP);
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['Failed to add emoji. Please try again']]);
    });

    it('removes award if already awarded', async () => {
      const removeAwardEmojiMutationHandler = removeAwardEmojiMutationSuccessHandler;
      createComponent({ removeAwardEmojiMutationHandler });

      findAwardsList().vm.$emit('award', EMOJI_THUMBS_DOWN);
      await waitForPromises();

      expect(removeAwardEmojiMutationHandler).toHaveBeenCalledWith({
        awardableId: firstNote.id,
        name: EMOJI_THUMBS_DOWN,
      });
    });

    it('restores award if remove fails', async () => {
      createComponent({ removeAwardEmojiMutationHandler: jest.fn().mockRejectedValue('oh no') });

      findAwardsList().vm.$emit('award', EMOJI_THUMBS_DOWN);
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['Failed to remove emoji. Please try again']]);
    });
  });
});
