import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import mockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import WorkItemNoteAwardsList from '~/work_items/components/notes/work_item_note_awards_list.vue';
import addAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_add_award_emoji.mutation.graphql';
import removeAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_remove_award_emoji.mutation.graphql';
import groupWorkItemNotesByIidQuery from '~/work_items/graphql/notes/group_work_item_notes_by_iid.query.graphql';
import workItemNotesByIidQuery from '~/work_items/graphql/notes/work_item_notes_by_iid.query.graphql';
import {
  mockWorkItemNotesResponseWithComments,
  mockAwardEmojiThumbsUp,
} from 'jest/work_items/mock_data';
import { EMOJI_THUMBSUP, EMOJI_THUMBSDOWN } from '~/work_items/constants';

Vue.use(VueApollo);

describe('Work Item Note Awards List', () => {
  let wrapper;
  const { workItem } = mockWorkItemNotesResponseWithComments.data.workspace;
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
    isGroup = false,
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
      ...mockWorkItemNotesResponseWithComments,
    });

    wrapper = shallowMount(WorkItemNoteAwardsList, {
      provide: {
        isGroup,
      },
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

    it.each`
      isGroup  | query
      ${true}  | ${groupWorkItemNotesByIidQuery}
      ${false} | ${workItemNotesByIidQuery}
    `(
      'adds award if not already awarded in both group and project contexts',
      async ({ isGroup, query }) => {
        createComponent({ isGroup, query });
        await waitForPromises();

        findAwardsList().vm.$emit('award', EMOJI_THUMBSUP);

        expect(addAwardEmojiMutationSuccessHandler).toHaveBeenCalledWith({
          awardableId: firstNote.id,
          name: EMOJI_THUMBSUP,
        });
      },
    );

    it('emits error if awarding emoji fails', async () => {
      createComponent({ addAwardEmojiMutationHandler: jest.fn().mockRejectedValue('oh no') });

      findAwardsList().vm.$emit('award', EMOJI_THUMBSUP);
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[__('Failed to add emoji. Please try again')]]);
    });

    it.each`
      isGroup  | query
      ${true}  | ${groupWorkItemNotesByIidQuery}
      ${false} | ${workItemNotesByIidQuery}
    `(
      'removes award if already awarded in both group and project contexts',
      async ({ isGroup, query }) => {
        const removeAwardEmojiMutationHandler = removeAwardEmojiMutationSuccessHandler;
        createComponent({ isGroup, query, removeAwardEmojiMutationHandler });

        findAwardsList().vm.$emit('award', EMOJI_THUMBSDOWN);
        await waitForPromises();

        expect(removeAwardEmojiMutationHandler).toHaveBeenCalledWith({
          awardableId: firstNote.id,
          name: EMOJI_THUMBSDOWN,
        });
      },
    );

    it('restores award if remove fails', async () => {
      createComponent({ removeAwardEmojiMutationHandler: jest.fn().mockRejectedValue('oh no') });

      findAwardsList().vm.$emit('award', EMOJI_THUMBSDOWN);
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[__('Failed to remove emoji. Please try again')]]);
    });
  });
});
