import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import EmojiPicker from '~/emoji/components/picker.vue';
import waitForPromises from 'helpers/wait_for_promises';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import WorkItemNoteActions from '~/work_items/components/notes/work_item_note_actions.vue';
import addAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_add_award_emoji.mutation.graphql';

Vue.use(VueApollo);

describe('Work Item Note Actions', () => {
  let wrapper;
  const noteId = '1';

  const findReplyButton = () => wrapper.findComponent(ReplyButton);
  const findEditButton = () => wrapper.find('[data-testid="edit-work-item-note"]');
  const findEmojiButton = () => wrapper.find('[data-testid="note-emoji-button"]');

  const addEmojiMutationResolver = jest.fn().mockResolvedValue({
    data: {
      errors: [],
    },
  });

  const EmojiPickerStub = {
    props: EmojiPicker.props,
    template: '<div></div>',
  };

  const createComponent = ({ showReply = true, showEdit = true, showAwardEmoji = true } = {}) => {
    wrapper = shallowMount(WorkItemNoteActions, {
      propsData: {
        showReply,
        showEdit,
        noteId,
        showAwardEmoji,
      },
      provide: {
        glFeatures: {
          workItemsMvc2: true,
        },
      },
      stubs: {
        EmojiPicker: EmojiPickerStub,
      },
      apolloProvider: createMockApollo([[addAwardEmojiMutation, addEmojiMutationResolver]]),
    });
  };

  describe('reply button', () => {
    it('is visible by default', () => {
      createComponent();

      expect(findReplyButton().exists()).toBe(true);
    });

    it('is hidden when showReply false', () => {
      createComponent({ showReply: false });

      expect(findReplyButton().exists()).toBe(false);
    });
  });

  describe('edit button', () => {
    it('is visible when `showEdit` prop is true', () => {
      createComponent();

      expect(findEditButton().exists()).toBe(true);
    });

    it('is hidden when `showEdit` prop is false', () => {
      createComponent({ showEdit: false });

      expect(findEditButton().exists()).toBe(false);
    });

    it('emits `startEditing` event when clicked', () => {
      createComponent();
      findEditButton().vm.$emit('click');

      expect(wrapper.emitted('startEditing')).toEqual([[]]);
    });
  });

  describe('emoji picker', () => {
    it('is visible when `showAwardEmoji` prop is true', () => {
      createComponent();

      expect(findEmojiButton().exists()).toBe(true);
    });

    it('is hidden when `showAwardEmoji` prop is false', () => {
      createComponent({ showAwardEmoji: false });

      expect(findEmojiButton().exists()).toBe(false);
    });

    it('commits mutation on click', async () => {
      const awardName = 'carrot';

      createComponent();

      findEmojiButton().vm.$emit('click', awardName);

      await waitForPromises();

      expect(findEmojiButton().emitted('errors')).toEqual(undefined);
      expect(addEmojiMutationResolver).toHaveBeenCalledWith({
        awardableId: noteId,
        name: awardName,
      });
    });
  });
});
