import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import noteActions from '~/notes/components/note_actions.vue';
import { NOTEABLE_TYPE_MAPPING } from '~/notes/constants';
import TimelineEventButton from '~/notes/components/note_actions/timeline_event_button.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import createStore from '~/notes/stores';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { userDataMock } from '../mock_data';

describe('noteActions', () => {
  let wrapper;
  let store;
  let props;
  let actions;
  let axiosMock;

  const mockCloseDropdown = jest.fn();

  const findUserAccessRoleBadge = (idx) => wrapper.findAllComponents(UserAccessRoleBadge).at(idx);
  const findUserAccessRoleBadgeText = (idx) => findUserAccessRoleBadge(idx).text().trim();
  const findTimelineButton = () => wrapper.findComponent(TimelineEventButton);
  const findReportAbuseButton = () => wrapper.find(`[data-testid="report-abuse-button"]`);
  const findDisclosureDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);

  const setupStoreForIncidentTimelineEvents = ({
    userCanAdd,
    noteableType,
    isPromotionInProgress = true,
  }) => {
    store.dispatch('setUserData', {
      ...userDataMock,
      can_add_timeline_events: userCanAdd,
    });
    store.state.noteableData = {
      ...store.state.noteableData,
      type: noteableType,
    };
    store.state.isPromoteCommentToTimelineEventInProgress = isPromotionInProgress;
  };

  const mountNoteActions = (propsData) => {
    return shallowMount(noteActions, {
      store,
      propsData,
      stubs: {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          methods: {
            close: mockCloseDropdown,
          },
        }),
        GlDisclosureDropdownGroup,
        GlDisclosureDropdownItem,
      },
    });
  };

  beforeEach(() => {
    store = createStore();

    props = {
      accessLevel: 'Maintainer',
      authorId: 1,
      author: userDataMock,
      canDelete: true,
      canEdit: true,
      canAwardEmoji: true,
      canReportAsAbuse: true,
      isAuthor: true,
      isContributor: false,
      noteableType: 'MergeRequest',
      noteId: '539',
      noteUrl: `${TEST_HOST}/group/project/-/merge_requests/1#note_1`,
      projectName: 'project',
      showReply: false,
      awardPath: `${TEST_HOST}/award_emoji`,
    };

    actions = {
      updateAssignees: jest.fn(),
    };

    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('user is logged in', () => {
    beforeEach(() => {
      store.dispatch('setUserData', userDataMock);

      wrapper = mountNoteActions(props);
    });

    it('should render noteable author badge', () => {
      expect(findUserAccessRoleBadgeText(0)).toBe('Author');
    });

    it('should render access level badge', () => {
      expect(findUserAccessRoleBadgeText(1)).toBe(props.accessLevel);
    });

    it('should render contributor badge', async () => {
      wrapper.setProps({
        accessLevel: null,
        isContributor: true,
      });

      await nextTick();
      expect(findUserAccessRoleBadgeText(1)).toBe('Contributor');
    });

    it('should render emoji link', () => {
      expect(wrapper.find('[data-testid="note-emoji-button"]').exists()).toBe(true);
    });

    describe('actions dropdown group', () => {
      it('should render the dropdown group when canReportAsAbuse is true', async () => {
        wrapper.setProps({ canReportAsAbuse: true });
        await nextTick();
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should render the dropdown group when canEdit is true', async () => {
        wrapper.setProps({ canEdit: true });
        await nextTick();
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should render the dropdown group when both canReportAsAbuse and canEdit are true', async () => {
        wrapper.setProps({ canReportAsAbuse: true, canEdit: true });
        await nextTick();
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should not render the dropdown group when neither canReportAsAbuse nor canEdit is true', async () => {
        wrapper.setProps({ canReportAsAbuse: false, canEdit: false });
        await nextTick();
        expect(findDisclosureDropdownGroup().exists()).toBe(false);
      });
    });

    describe('actions dropdown', () => {
      it('should be possible to edit the comment', () => {
        expect(wrapper.find('.js-note-edit').exists()).toBe(true);
      });

      it('should be possible to report abuse to admin', () => {
        expect(findReportAbuseButton().exists()).toBe(true);
      });

      it('should be possible to copy link to a note', () => {
        expect(wrapper.find('.js-btn-copy-note-link').exists()).toBe(true);
      });

      it('should not show copy link action when `noteUrl` prop is empty', async () => {
        wrapper.setProps({
          ...props,
          author: {
            avatar_url: 'mock_path',
            id: 26,
            name: 'Example Maintainer',
            path: '/ExampleMaintainer',
            state: 'active',
            username: 'ExampleMaintainer',
          },
          noteUrl: '',
        });

        await nextTick();
        expect(wrapper.find('.js-btn-copy-note-link').exists()).toBe(false);
      });

      it('should be possible to delete comment', () => {
        expect(wrapper.find('.js-note-delete').exists()).toBe(true);
      });

      it('should not be possible to assign or unassign the comment author in a merge request', () => {
        const assignUserButton = wrapper.find('[data-testid="assign-user"]');
        expect(assignUserButton.exists()).toBe(false);
      });

      it('should render the correct (unescaped) name in the Resolved By tooltip', () => {
        const complexUnescapedName = 'This is a Ǝ\'𝞓\'E "cat"?';
        wrapper = mountNoteActions({
          ...props,
          canResolve: true,
          isResolving: false,
          isResolved: true,
          resolvedBy: {
            name: complexUnescapedName,
          },
        });

        const { resolveButton } = wrapper.vm.$refs;
        expect(resolveButton.$el.getAttribute('title')).toBe(`Resolved by ${complexUnescapedName}`);
      });
    });
  });

  describe('when a user can set metadata of an issue', () => {
    const testButtonClickTriggersAction = () => {
      axiosMock.onPut(`${TEST_HOST}/api/v4/projects/group/project/issues/1`).reply(() => {
        expect(actions.updateAssignees).toHaveBeenCalled();
      });

      const assignUserButton = wrapper.find('[data-testid="assign-user"]');
      expect(assignUserButton.exists()).toBe(true);
      assignUserButton.trigger('click');
    };

    beforeEach(() => {
      wrapper = mountNoteActions(props);
      store.state.noteableData = {
        current_user: {
          can_set_issue_metadata: true,
        },
      };
      store.state.userData = userDataMock;
      store.state.noteableData.targetType = 'issue';
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('should be possible to assign the comment author', testButtonClickTriggersAction);
    it('should be possible to unassign the comment author', testButtonClickTriggersAction);
  });

  describe('when a user can update but not set metadata of an issue', () => {
    beforeEach(() => {
      wrapper = mountNoteActions(props, {
        targetType: () => 'issue',
      });
      store.state.noteableData = {
        current_user: {
          can_update: true,
          can_set_issue_metadata: false,
        },
      };
      store.state.userData = userDataMock;
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('should not be possible to assign or unassign the comment author', () => {
      const assignUserButton = wrapper.find('[data-testid="assign-user"]');
      expect(assignUserButton.exists()).toBe(false);
    });
  });

  describe('when a user does not have access to edit an issue', () => {
    const testButtonDoesNotRender = () => {
      const assignUserButton = wrapper.find('[data-testid="assign-user"]');
      expect(assignUserButton.exists()).toBe(false);
    };

    beforeEach(() => {
      wrapper = mountNoteActions(props, {
        targetType: () => 'issue',
      });
    });

    it('should not be possible to assign the comment author', testButtonDoesNotRender);
    it('should not be possible to unassign the comment author', testButtonDoesNotRender);
  });

  describe('user is not logged in', () => {
    beforeEach(() => {
      // userData can be null https://gitlab.com/gitlab-org/gitlab/-/issues/379375
      store.dispatch('setUserData', null);
      wrapper = mountNoteActions({
        ...props,
        canDelete: false,
        canEdit: false,
        canAwardEmoji: false,
        canReportAsAbuse: false,
      });
    });

    it('should not render emoji link', () => {
      expect(wrapper.find('.js-add-award').exists()).toBe(false);
    });

    it('should not render actions dropdown', () => {
      expect(wrapper.find('.more-actions').exists()).toBe(false);
    });
  });

  describe('for showReply = true', () => {
    beforeEach(() => {
      wrapper = mountNoteActions({
        ...props,
        showReply: true,
      });
    });

    it('shows a reply button', () => {
      const replyButton = wrapper.findComponent({ ref: 'replyButton' });

      expect(replyButton.exists()).toBe(true);
    });
  });

  describe('for showReply = false', () => {
    beforeEach(() => {
      wrapper = mountNoteActions({
        ...props,
        showReply: false,
      });
    });

    it('does not show a reply button', () => {
      const replyButton = wrapper.findComponent({ ref: 'replyButton' });

      expect(replyButton.exists()).toBe(false);
    });
  });

  describe('Draft notes', () => {
    beforeEach(() => {
      store.dispatch('setUserData', userDataMock);

      wrapper = mountNoteActions({ ...props, canResolve: true, isDraft: true });
    });

    it('should render the right resolve button title', () => {
      const resolveButton = wrapper.findComponent({ ref: 'resolveButton' });

      expect(resolveButton.exists()).toBe(true);
      expect(resolveButton.attributes('title')).toBe('Thread stays unresolved');
    });
  });

  describe('timeline event button', () => {
    // why: We are working with an integrated store, so let's imply the getter is used
    describe.each`
      desc                                         | userCanAdd | noteableType                          | exists
      ${'default'}                                 | ${true}    | ${NOTEABLE_TYPE_MAPPING.Incident}     | ${true}
      ${'when cannot add incident timeline event'} | ${false}   | ${NOTEABLE_TYPE_MAPPING.Incident}     | ${false}
      ${'when is not incident'}                    | ${true}    | ${NOTEABLE_TYPE_MAPPING.MergeRequest} | ${false}
    `('$desc', ({ userCanAdd, noteableType, exists }) => {
      beforeEach(() => {
        setupStoreForIncidentTimelineEvents({
          userCanAdd,
          noteableType,
        });

        wrapper = mountNoteActions({ ...props });
      });

      it(`handles rendering of timeline button (exists=${exists})`, () => {
        expect(findTimelineButton().exists()).toBe(exists);
      });
    });

    describe('default', () => {
      beforeEach(() => {
        setupStoreForIncidentTimelineEvents({
          userCanAdd: true,
          noteableType: NOTEABLE_TYPE_MAPPING.Incident,
        });

        wrapper = mountNoteActions({ ...props });
      });

      it('should render timeline-event-button', () => {
        expect(findTimelineButton().props()).toEqual({
          noteId: props.noteId,
          isPromotionInProgress: true,
        });
      });

      it('when timeline-event-button emits click-promote-comment-to-event, dispatches action', () => {
        jest.spyOn(store, 'dispatch').mockImplementation();

        expect(store.dispatch).not.toHaveBeenCalled();

        findTimelineButton().vm.$emit('click-promote-comment-to-event');

        expect(store.dispatch).toHaveBeenCalledTimes(1);
        expect(store.dispatch).toHaveBeenCalledWith('promoteCommentToTimelineEvent');
      });
    });
  });

  describe('report abuse button', () => {
    const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);

    describe('when user is not allowed to report abuse', () => {
      beforeEach(() => {
        store.dispatch('setUserData', userDataMock);
        wrapper = mountNoteActions({ ...props, canReportAsAbuse: false });
      });

      it('does not render the report abuse', () => {
        expect(findReportAbuseButton().exists()).toBe(false);
      });

      it('does not render the abuse category drawer', () => {
        expect(findAbuseCategorySelector().exists()).toBe(false);
      });
    });

    describe('when user is allowed to report abuse', () => {
      beforeEach(() => {
        store.dispatch('setUserData', userDataMock);
        wrapper = mountNoteActions({ ...props, canReportAsAbuse: true });
      });

      it('renders report abuse button', () => {
        expect(findReportAbuseButton().exists()).toBe(true);
      });

      it('does not render the abuse category drawer immediately', () => {
        expect(findAbuseCategorySelector().exists()).toBe(false);
      });

      it('opens the drawer when report abuse button is clicked', async () => {
        await findReportAbuseButton().vm.$emit('action');

        expect(findAbuseCategorySelector().props('showDrawer')).toEqual(true);
      });

      it('closes the drawer', async () => {
        await findReportAbuseButton().vm.$emit('action');
        findAbuseCategorySelector().vm.$emit('close-drawer');

        await nextTick();

        expect(findAbuseCategorySelector().exists()).toEqual(false);
      });
    });
  });
});
