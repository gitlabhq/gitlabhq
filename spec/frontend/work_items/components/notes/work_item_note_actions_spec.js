import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { stubComponent } from 'helpers/stub_component';
import EmojiPicker from '~/emoji/components/picker.vue';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import WorkItemNoteActions from '~/work_items/components/notes/work_item_note_actions.vue';
import addAwardEmojiMutation from '~/work_items/graphql/notes/work_item_note_add_award_emoji.mutation.graphql';

jest.mock('~/work_items/notes/award_utils', () => ({
  ...jest.requireActual('~/work_items/notes/award_utils'),
  getNewCustomEmojiPath: jest.fn().mockReturnValue('/groups/gitlab-org/-/custom_emoji/new'),
}));

Vue.use(VueApollo);

describe('Work Item Note Actions', () => {
  let wrapper;
  const showSpy = jest.fn();

  const findReplyButton = () => wrapper.findComponent(ReplyButton);
  const findEditButton = () => wrapper.findComponentByTestId('note-edit-button');
  const findEmojiButton = () => wrapper.findComponentByTestId('note-emoji-button');
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDeleteNoteButton = () => wrapper.findComponentByTestId('delete-note-action');
  const findCopyLinkButton = () => wrapper.findComponentByTestId('copy-link-action');
  const findAssignUnassignButton = () => wrapper.findComponentByTestId('assign-note-action');
  const findReportAbuseToAdminButton = () => wrapper.findComponentByTestId('abuse-note-action');
  const findAuthorBadge = () => wrapper.findByTestId('author-badge');
  const findMaxAccessLevelBadge = () => wrapper.findByTestId('max-access-level-badge');
  const findContributorBadge = () => wrapper.findByTestId('contributor-badge');
  const findDisclosureDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findCompactActionsGroup = () => wrapper.findByTestId('compact-actions-group');
  const findEditNoteAction = () => wrapper.findComponentByTestId('edit-note-action');

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
    duoSessionId = null,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemNoteActions, {
      propsData: {
        fullPath: 'gitlab-org',
        showReply,
        showEdit,
        workItemIid: '1',
        note: {},
        showAwardEmoji,
        showAssignUnassign,
        canReportAbuse,
        workItemType,
        isWorkItemAuthor,
        isAuthorContributor,
        maxAccessLevelOfAuthor,
        projectName,
        duoSessionId,
      },
      stubs: {
        EmojiPicker,
        ViewSessionButton: stubComponent({
          name: 'ViewSessionButton',
          props: {
            sessionId: { type: Number, required: true },
            asDropdownItem: { type: Boolean, required: false, default: false },
          },
        }),
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

    it('is only shown inline above the sm breakpoint', () => {
      createComponent();

      expect(findEditButton().classes()).toContain('note-hidden-xs');
    });

    it('is hidden when `showEdit` prop is false', () => {
      createComponent({ showEdit: false });

      expect(findEditButton().exists()).toBe(false);
    });

    it('emits `start-editing` event when clicked', () => {
      createComponent();
      findEditButton().vm.$emit('click');

      expect(wrapper.emitted('start-editing')).toEqual([[]]);
    });
  });

  describe('compact actions in the overflow menu', () => {
    it('is not rendered when there is no session and the user cannot edit', () => {
      createComponent({ showEdit: false, duoSessionId: null });

      expect(findCompactActionsGroup().exists()).toBe(false);
    });

    it.each`
      showEdit | duoSessionId
      ${true}  | ${null}
      ${false} | ${42}
      ${true}  | ${42}
    `(
      'is rendered and hidden above the sm breakpoint when showEdit=$showEdit and duoSessionId=$duoSessionId',
      ({ showEdit, duoSessionId }) => {
        createComponent({ showEdit, duoSessionId });

        expect(findCompactActionsGroup().exists()).toBe(true);
        expect(findCompactActionsGroup().classes()).toContain('note-only-xs');
      },
    );

    describe('edit action', () => {
      it('is rendered when `showEdit` prop is true', () => {
        createComponent({ showEdit: true });

        expect(findEditNoteAction().exists()).toBe(true);
      });

      it('is not rendered when `showEdit` prop is false', () => {
        createComponent({ showEdit: false });

        expect(findEditNoteAction().exists()).toBe(false);
      });

      it('is tracked the same as the inline edit button', () => {
        createComponent({ showEdit: true });

        expect(findEditNoteAction().attributes()).toMatchObject({
          'data-track-action': 'click_button',
          'data-track-label': 'edit_button',
        });
      });

      it('emits `start-editing` and closes the dropdown when clicked', () => {
        createComponent({ showEdit: true });

        findEditNoteAction().vm.$emit('action');

        expect(wrapper.emitted('start-editing')).toEqual([[]]);
        expect(showSpy).toHaveBeenCalled();
      });
    });
  });

  describe('emoji picker', () => {
    it('is visible when `showAwardEmoji` prop is true', () => {
      createComponent();

      expect(findEmojiButton().exists()).toBe(true);
      expect(findEmojiButton().props('customEmojiPath')).toBe(
        '/groups/gitlab-org/-/custom_emoji/new',
      );
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

    it('should emit `delete-note` event when delete note action is clicked', () => {
      createComponent({
        showEdit: true,
      });

      findDeleteNoteButton().vm.$emit('action');

      expect(wrapper.emitted('delete-note')).toEqual([[]]);
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

    it('should emit `notify-copy-done` event when copy link note action is clicked', () => {
      findCopyLinkButton().vm.$emit('action');

      expect(wrapper.emitted('notify-copy-done')).toEqual([[]]);
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

    it('should emit `assign-user` event when assign note action is clicked', () => {
      createComponent({
        showAssignUnassign: true,
      });

      findAssignUnassignButton().vm.$emit('action');

      expect(wrapper.emitted('assign-user')).toEqual([[]]);
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

    it('should emit `report-abuse` event when report abuse action is clicked', () => {
      createComponent({
        canReportAbuse: true,
      });

      findReportAbuseToAdminButton().vm.$emit('action');

      expect(wrapper.emitted('report-abuse')).toEqual([[]]);
      expect(showSpy).toHaveBeenCalled();
    });
  });

  describe('view session button', () => {
    const findViewSessionButton = () => wrapper.findComponentByTestId('view-session-button');
    const findViewSessionAction = () => wrapper.findComponentByTestId('view-session-action');

    describe('when the note has no linked session', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render the view session button', () => {
        expect(findViewSessionButton().exists()).toBe(false);
      });

      it('does not render the view session overflow menu item', () => {
        expect(findViewSessionAction().exists()).toBe(false);
      });
    });

    describe('when the note has a linked session', () => {
      beforeEach(() => {
        createComponent({ duoSessionId: 42 });
      });

      it('renders the view session button', () => {
        expect(findViewSessionButton().exists()).toBe(true);
      });

      it('passes the session id to the view session button', () => {
        expect(findViewSessionButton().props('sessionId')).toBe(42);
      });

      it('only shows the inline button above the sm breakpoint', () => {
        expect(findViewSessionButton().props('asDropdownItem')).toBe(false);
        expect(findViewSessionButton().classes()).toContain('note-hidden-xs');
      });

      it('renders the view session overflow menu item with the session id', () => {
        expect(findViewSessionAction().props()).toEqual({
          sessionId: 42,
          asDropdownItem: true,
        });
      });
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
