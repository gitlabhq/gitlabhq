import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { stubComponent } from 'helpers/stub_component';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import WorkItemNoteActions from '~/work_items/components/notes/work_item_note_actions.vue';
import addAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_add_award_emoji.mutation.graphql';

Vue.use(VueApollo);

describe('Work Item Note Actions', () => {
  let wrapper;
  const noteId = '1';
  const showSpy = jest.fn();

  const findReplyButton = () => wrapper.findComponent(ReplyButton);
  const findEditButton = () => wrapper.findByTestId('note-actions-edit');
  const findEmojiButton = () => wrapper.findByTestId('note-emoji-button');
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDeleteNoteButton = () => wrapper.findByTestId('delete-note-action');
  const findCopyLinkButton = () => wrapper.findByTestId('copy-link-action');
  const findAssignUnassignButton = () => wrapper.findByTestId('assign-note-action');
  const findReportAbuseToAdminButton = () => wrapper.findByTestId('abuse-note-action');
  const findAuthorBadge = () => wrapper.findByTestId('author-badge');
  const findMaxAccessLevelBadge = () => wrapper.findByTestId('max-access-level-badge');
  const findContributorBadge = () => wrapper.findByTestId('contributor-badge');
  const findDisclosureDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);

  const addEmojiMutationResolver = jest.fn().mockResolvedValue({
    data: {
      errors: [],
    },
  });

  const createComponent = ({
    showReply = true,
    showEdit = true,
    showAwardEmoji = true,
    showAssignUnassign = false,
    canReportAbuse = false,
    workItemType = 'Task',
    isWorkItemAuthor = false,
    isAuthorContributor = false,
    maxAccessLevelOfAuthor = '',
    projectName = 'Project name',
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemNoteActions, {
      propsData: {
        fullPath: 'gitlab-org',
        showReply,
        showEdit,
        workItemIid: '1',
        note: {},
        noteId,
        showAwardEmoji,
        showAssignUnassign,
        canReportAbuse,
        workItemType,
        isWorkItemAuthor,
        isAuthorContributor,
        maxAccessLevelOfAuthor,
        projectName,
      },
      provide: {
        glFeatures: {
          workItemsAlpha: true,
        },
      },
      stubs: {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          methods: { close: showSpy },
        }),
      },
      apolloProvider: createMockApollo([[addAwardEmojiMutation, addEmojiMutationResolver]]),
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  afterEach(() => {
    showSpy.mockClear();
  });

  describe('dropdown group', () => {
    it('renders dropdown group when either canReportAbuse or showEdit is true', () => {
      createComponent({ canReportAbuse: true, showEdit: true });

      expect(findDisclosureDropdownGroup().exists()).toBe(true);
    });

    it('does not render dropdown group when both canReportAbuse and showEdit are false', () => {
      createComponent({ canReportAbuse: false, showEdit: false });

      expect(findDisclosureDropdownGroup().exists()).toBe(false);
    });

    it('renders reportAbuse button inside dropdown group when canReportAbuse is true', () => {
      createComponent({ canReportAbuse: true });

      expect(findDisclosureDropdownGroup().exists()).toBe(true);
      expect(findReportAbuseToAdminButton().exists()).toBe(true);
    });

    it('renders delete note button inside dropdown group when showEdit is true', () => {
      createComponent({ showEdit: true });

      expect(findDisclosureDropdownGroup().exists()).toBe(true);
      expect(findDeleteNoteButton().exists()).toBe(true);
    });

    it('renders both reportAbuse and delete note buttons when both canReportAbuse and showEdit are true', () => {
      createComponent({ canReportAbuse: true, showEdit: true });

      expect(findDisclosureDropdownGroup().exists()).toBe(true);
      expect(findReportAbuseToAdminButton().exists()).toBe(true);
      expect(findDeleteNoteButton().exists()).toBe(true);
    });
  });

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

      findDeleteNoteButton().vm.$emit('action');

      expect(wrapper.emitted('deleteNote')).toEqual([[]]);
      expect(showSpy).toHaveBeenCalled();
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
      findCopyLinkButton().vm.$emit('action');

      expect(wrapper.emitted('notifyCopyDone')).toEqual([[]]);
      expect(showSpy).toHaveBeenCalled();
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

      findAssignUnassignButton().vm.$emit('action');

      expect(wrapper.emitted('assignUser')).toEqual([[]]);
      expect(showSpy).toHaveBeenCalled();
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

      findReportAbuseToAdminButton().vm.$emit('action');

      expect(wrapper.emitted('reportAbuse')).toEqual([[]]);
      expect(showSpy).toHaveBeenCalled();
    });
  });

  describe('user role badges', () => {
    describe('author badge', () => {
      it('does not show the author badge by default', () => {
        createComponent();

        expect(findAuthorBadge().exists()).toBe(false);
      });

      it('shows the author badge when the work item is author by the current User', () => {
        createComponent({ isWorkItemAuthor: true });

        expect(findAuthorBadge().exists()).toBe(true);
        expect(findAuthorBadge().text()).toBe('Author');
        expect(findAuthorBadge().attributes('title')).toBe('This user is the author of this task.');
      });
    });

    describe('Max access level badge', () => {
      it('does not show the access level badge by default', () => {
        createComponent();

        expect(findMaxAccessLevelBadge().exists()).toBe(false);
      });

      it('shows the access badge when we have a valid value', () => {
        createComponent({ maxAccessLevelOfAuthor: 'Owner' });

        expect(findMaxAccessLevelBadge().exists()).toBe(true);
        expect(findMaxAccessLevelBadge().text()).toBe('Owner');
        expect(findMaxAccessLevelBadge().attributes('title')).toBe(
          'This user has the owner role in the Project name project.',
        );
      });
    });

    describe('Contributor badge', () => {
      it('does not show the contributor badge by default', () => {
        createComponent();

        expect(findContributorBadge().exists()).toBe(false);
      });

      it('shows the contributor badge the note author is a contributor', () => {
        createComponent({ isAuthorContributor: true });

        expect(findContributorBadge().exists()).toBe(true);
        expect(findContributorBadge().text()).toBe('Contributor');
        expect(findContributorBadge().attributes('title')).toBe(
          'This user has previously committed to the Project name project.',
        );
      });
    });
  });
});
