import { GlDropdown } from '@gitlab/ui';
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
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDeleteNoteButton = () => wrapper.find('[data-testid="delete-note-action"]');
  const findCopyLinkButton = () => wrapper.find('[data-testid="copy-link-action"]');
  const findAssignUnassignButton = () => wrapper.find('[data-testid="assign-note-action"]');
  const findReportAbuseToAdminButton = () => wrapper.find('[data-testid="abuse-note-action"]');

  const addEmojiMutationResolver = jest.fn().mockResolvedValue({
    data: {
      errors: [],
    },
  });

  const EmojiPickerStub = {
    props: EmojiPicker.props,
    template: '<div></div>',
  };

  const createComponent = ({
    showReply = true,
    showEdit = true,
    showAwardEmoji = true,
    showAssignUnassign = false,
    canReportAbuse = false,
  } = {}) => {
    wrapper = shallowMount(WorkItemNoteActions, {
      propsData: {
        showReply,
        showEdit,
        noteId,
        showAwardEmoji,
        showAssignUnassign,
        canReportAbuse,
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

  describe('delete note', () => {
    it('should display the `Delete comment` dropdown item if user has a permission to delete a note', () => {
      createComponent({
        showEdit: true,
      });

      expect(findDropdown().exists()).toBe(true);
      expect(findDeleteNoteButton().exists()).toBe(true);
    });

    it('should not display the `Delete comment` dropdown item if user has no permission to delete a note', () => {
      createComponent({
        showEdit: false,
      });

      expect(findDropdown().exists()).toBe(true);
      expect(findDeleteNoteButton().exists()).toBe(false);
    });

    it('should emit `deleteNote` event when delete note action is clicked', () => {
      createComponent({
        showEdit: true,
      });

      findDeleteNoteButton().vm.$emit('click');

      expect(wrapper.emitted('deleteNote')).toEqual([[]]);
    });
  });

  describe('copy link', () => {
    beforeEach(() => {
      createComponent({});
    });
    it('should display Copy link always', () => {
      expect(findCopyLinkButton().exists()).toBe(true);
    });

    it('should emit `notifyCopyDone` event when copy link note action is clicked', () => {
      findCopyLinkButton().vm.$emit('click');

      expect(wrapper.emitted('notifyCopyDone')).toEqual([[]]);
    });
  });

  describe('assign/unassign to commenting user', () => {
    it('should not display assign/unassign by default', () => {
      createComponent();

      expect(findAssignUnassignButton().exists()).toBe(false);
    });

    it('should display assign/unassign when the props is true', () => {
      createComponent({
        showAssignUnassign: true,
      });

      expect(findAssignUnassignButton().exists()).toBe(true);
    });

    it('should emit `assignUser` event when assign note action is clicked', () => {
      createComponent({
        showAssignUnassign: true,
      });

      findAssignUnassignButton().vm.$emit('click');

      expect(wrapper.emitted('assignUser')).toEqual([[]]);
    });
  });

  describe('report abuse to admin', () => {
    it('should not report abuse to admin by default', () => {
      createComponent();

      expect(findReportAbuseToAdminButton().exists()).toBe(false);
    });

    it('should display assign/unassign when the props is true', () => {
      createComponent({
        canReportAbuse: true,
      });

      expect(findReportAbuseToAdminButton().exists()).toBe(true);
    });

    it('should emit `reportAbuse` event when report abuse action is clicked', () => {
      createComponent({
        canReportAbuse: true,
      });

      findReportAbuseToAdminButton().vm.$emit('click');

      expect(wrapper.emitted('reportAbuse')).toEqual([[]]);
    });
  });
});
