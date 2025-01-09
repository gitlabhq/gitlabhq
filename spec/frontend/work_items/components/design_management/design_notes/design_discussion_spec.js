import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import mockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { isLoggedIn } from '~/lib/utils/common_utils';
import getDesignQuery from '~/work_items/components/design_management/graphql/design_details.query.graphql';
import DesignDiscussion from '~/work_items/components/design_management/design_notes/design_discussion.vue';
import DesignNote from '~/work_items/components/design_management/design_notes/design_note.vue';
import DesignNoteSignedOut from '~/work_items/components/design_management/design_notes/design_note_signed_out.vue';
import DesignReplyForm from '~/work_items/components/design_management/design_notes/design_reply_form.vue';
import DiscussionReplyPlaceholder from '~/work_items/components/design_management/design_notes/discussion_reply_placeholder.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import ToggleRepliesWidget from '~/work_items/components/design_management/design_notes/toggle_replies_widget.vue';
import toggleResolveDiscussionMutation from '~/work_items/components/design_management/graphql/toggle_resolve_discussion.mutation.graphql';
import destroyNoteMutation from '~/work_items/components/design_management/graphql/destroy_note.mutation.graphql';
import {
  DELETE_NOTE_ERROR,
  RESOLVE_NOTE_ERROR,
} from '~/work_items/components/design_management/constants';
import { resolvers } from '~/graphql_shared/issuable_client';
import activeDiscussionQuery from '~/work_items/components/design_management/graphql/client/active_design_discussion.query.graphql';
import { mockResolveDiscussionMutationResponse, getDesignResponse } from '../mock_data';
import notes, { DISCUSSION_1 } from './mock_notes';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
Vue.use(VueApollo);

const defaultMockDiscussion = {
  id: '0',
  resolved: false,
  resolvable: true,
  notes,
};

const designVariables = {
  id: 'gid://gitlab/DesignManagement::DesignAtVersion/33.1',
};

describe('Design discussions component', () => {
  let wrapper;
  let apolloProvider;

  const findDesignNotesList = () => wrapper.find('[data-testid="design-discussion-content"]');
  const findDesignNotes = () => wrapper.findAllComponents(DesignNote);
  const findReplyPlaceholder = () => wrapper.findComponent(DiscussionReplyPlaceholder);
  const findReplyForm = () => wrapper.findComponent(DesignReplyForm);
  const findRepliesWidget = () => wrapper.findComponent(ToggleRepliesWidget);
  const findResolveButton = () => wrapper.find('[data-testid="resolve-button"]');
  const findResolvedMessage = () => wrapper.find('[data-testid="resolved-message"]');
  const findResolveCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findDesignNoteSignedOut = () => wrapper.findComponent(DesignNoteSignedOut);

  const resolveDiscussionSuccessMutationHandler = jest
    .fn()
    .mockResolvedValue(mockResolveDiscussionMutationResponse);
  const resolveMutationErrorHandler = jest.fn().mockRejectedValue(new Error(RESOLVE_NOTE_ERROR));

  const destroyNoteSuccessMutationHandler = jest.fn().mockResolvedValue({
    data: { destroyNote: { note: null, __typename: 'DestroyNote', errors: [] } },
  });
  const deleteMutationErrorHandler = jest.fn().mockRejectedValue(new Error(DELETE_NOTE_ERROR));

  const registerPath = '/users/sign_up?redirect_to_referer=yes';
  const signInPath = '/users/sign_in?redirect_to_referer=yes';

  function createComponent({
    resolveDiscussionMutationHandler = resolveDiscussionSuccessMutationHandler,
    destroyNoteMutationHandler = destroyNoteSuccessMutationHandler,
    props = {},
    data = {},
  } = {}) {
    apolloProvider = mockApollo(
      [
        [toggleResolveDiscussionMutation, resolveDiscussionMutationHandler],
        [destroyNoteMutation, destroyNoteMutationHandler],
      ],
      resolvers,
    );
    apolloProvider.clients.defaultClient.writeQuery({
      query: activeDiscussionQuery,
      data: {
        activeDesignDiscussion: {
          __typename: 'ActiveDiscussion',
          id: data.activeDesignDiscussion?.id || null,
          source: data.activeDesignDiscussion?.source || null,
        },
      },
    });
    apolloProvider.clients.defaultClient.writeQuery({
      query: getDesignQuery,
      variables: designVariables,
      data: getDesignResponse.data,
    });

    wrapper = shallowMountExtended(DesignDiscussion, {
      apolloProvider,
      isLoggedIn: isLoggedIn(),
      propsData: {
        resolvedDiscussionsExpanded: true,
        discussionWithOpenForm: '',
        discussion: defaultMockDiscussion,
        noteableId: 'noteable-id',
        registerPath,
        signInPath,
        designVariables,
        ...props,
      },
      data() {
        return {
          activeDesignDiscussion: {
            id: null,
            source: null,
          },
          ...data,
        };
      },
      mocks: {
        $route: {
          hash: '#note_1',
          params: {
            id: 1,
          },
          query: {
            version: 1,
          },
        },
      },
    });
  }

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
  });

  afterEach(() => {
    apolloProvider = null;
  });

  describe('when discussion is not resolvable', () => {
    beforeEach(async () => {
      createComponent({
        props: {
          discussion: {
            ...defaultMockDiscussion,
            resolvable: false,
          },
        },
      });
      await waitForPromises();
    });

    it('does not render an icon to resolve a thread', () => {
      expect(findResolveButton().exists()).toBe(false);
    });

    it('does not render a checkbox in reply form', async () => {
      findReplyPlaceholder().vm.$emit('focus');

      await nextTick();
      expect(findResolveCheckbox().exists()).toBe(false);
    });
  });

  describe('when discussion is unresolved', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correct amount of discussion notes', () => {
      expect(findDesignNotes()).toHaveLength(2);
      expect(findDesignNotes().wrappers.every((w) => w.isVisible())).toBe(true);
    });

    it('renders reply placeholder', () => {
      expect(findReplyPlaceholder().isVisible()).toBe(true);
    });

    it('renders toggle replies widget', () => {
      expect(findRepliesWidget().exists()).toBe(true);
    });

    it('renders a correct icon to resolve a thread', () => {
      expect(findResolveButton().props('icon')).toBe('check-circle');
    });

    it('renders a checkbox with Resolve thread text in reply form', async () => {
      findReplyPlaceholder().vm.$emit('focus');
      wrapper.setProps({ discussionWithOpenForm: defaultMockDiscussion.id });

      await nextTick();
      expect(findResolveCheckbox().text()).toBe('Resolve thread');
    });

    it('does not render resolved message', () => {
      expect(findResolvedMessage().exists()).toBe(false);
    });

    it('renders toggle replies widget with correct props', () => {
      expect(findRepliesWidget().exists()).toBe(true);
      expect(findRepliesWidget().props()).toEqual({
        collapsed: false,
        replies: notes.slice(1),
      });
    });

    it('toggles toggleResolveDiscussion mutation on resolve thread button click', async () => {
      createComponent();

      findResolveButton().vm.$emit('click');
      await waitForPromises();

      expect(resolveDiscussionSuccessMutationHandler).toHaveBeenCalled();
    });

    it('emits `resolve-discussion-error` event if toggleResolveDiscussion fails', async () => {
      createComponent({ resolveDiscussionMutationHandler: resolveMutationErrorHandler });

      findResolveButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted()).toEqual({
        'resolve-discussion-error': [[RESOLVE_NOTE_ERROR]],
      });
    });
  });

  describe('when discussion is resolved', () => {
    beforeEach(() => {
      createComponent({
        props: {
          discussion: {
            ...defaultMockDiscussion,
            resolved: true,
            resolvedBy: notes[0].author,
            resolvedAt: '2020-05-08T07:10:45Z',
          },
        },
      });
    });

    it('shows only the first note', () => {
      expect(findDesignNotes().at(0).isVisible()).toBe(true);
      expect(findDesignNotes().at(1).isVisible()).toBe(false);
    });

    it('renders resolved message', () => {
      expect(findResolvedMessage().exists()).toBe(true);
    });

    it('does not show renders reply placeholder', () => {
      expect(findReplyPlaceholder().isVisible()).toBe(false);
    });

    it('renders toggle replies widget with correct props', () => {
      expect(findRepliesWidget().exists()).toBe(true);
      expect(findRepliesWidget().props()).toEqual({
        collapsed: true,
        replies: notes.slice(1),
      });
    });

    it('renders a correct icon to resolve a thread', () => {
      expect(findResolveButton().props('icon')).toBe('check-circle-filled');
    });

    describe('when replies are expanded', () => {
      beforeEach(async () => {
        findRepliesWidget().vm.$emit('toggle');
        await nextTick();
      });

      it('renders replies widget with collapsed prop equal to false', () => {
        expect(findRepliesWidget().props('collapsed')).toBe(false);
      });

      it('renders the second note', () => {
        expect(findDesignNotes().at(1).isVisible()).toBe(true);
      });

      it('renders a reply placeholder', () => {
        expect(findReplyPlaceholder().isVisible()).toBe(true);
      });

      it('renders a checkbox with Unresolve thread text in reply form', async () => {
        findReplyPlaceholder().vm.$emit('focus');
        wrapper.setProps({ discussionWithOpenForm: defaultMockDiscussion.id });

        await nextTick();
        expect(findResolveCheckbox().text()).toBe('Unresolve thread');
      });
    });

    it('hides reply placeholder and opens form on placeholder click', async () => {
      createComponent();
      findReplyPlaceholder().vm.$emit('focus');
      wrapper.setProps({ discussionWithOpenForm: defaultMockDiscussion.id });

      await nextTick();
      expect(findReplyPlaceholder().exists()).toBe(false);
      expect(findReplyForm().exists()).toBe(true);
    });

    it('closes the form when note submit mutation is completed', async () => {
      createComponent({
        props: { discussionWithOpenForm: defaultMockDiscussion.id },
        data: { isFormRendered: true },
      });

      findReplyForm().vm.$emit('note-submit-complete', { data: { createNote: {} } });

      await nextTick();

      expect(findReplyForm().exists()).toBe(false);
    });

    it('clears the discussion comment on closing comment form', async () => {
      createComponent({
        props: { discussionWithOpenForm: defaultMockDiscussion.id },
        data: { isFormRendered: true },
      });

      await nextTick();
      findReplyForm().vm.$emit('cancel-form');

      await nextTick();
      expect(findReplyForm().exists()).toBe(false);
    });
  });

  it('does not render toggle replies widget if there are no threads', () => {
    createComponent({
      props: {
        discussion: {
          id: 'gid://gitlab/Discussion/fac4739884a66ebe979480dab8a7cc151f9ab63a',
          notes: [{ ...notes[0], notes: [] }],
        },
      },
    });
    expect(findRepliesWidget().exists()).toBe(false);
  });

  describe('active discussions', () => {
    describe('when any note from a discussion is active', () => {
      it.each([notes[0], notes[0].discussion.notes.nodes[1]])(
        'applies correct class to the active discussion',
        (note) => {
          createComponent({
            props: { discussion: DISCUSSION_1 },
            data: {
              activeDesignDiscussion: {
                id: note.id,
                source: 'pin',
              },
            },
          });

          expect(findDesignNotesList().classes('gl-bg-blue-50')).toBe(true);
        },
      );
    });
  });

  describe('when user is not logged in', () => {
    beforeEach(() => {
      isLoggedIn.mockReturnValue(false);
      createComponent({
        props: {
          discussion: {
            ...defaultMockDiscussion,
          },
          discussionWithOpenForm: defaultMockDiscussion.id,
        },
        data: { isFormRendered: true },
      });
    });

    it('does not render resolve discussion button', () => {
      expect(findResolveButton().exists()).toBe(false);
    });

    it('does not render replace-placeholder component', () => {
      expect(findReplyPlaceholder().exists()).toBe(false);
    });

    it('renders design-note-signed-out component', () => {
      expect(findDesignNoteSignedOut().exists()).toBe(true);
      expect(findDesignNoteSignedOut().props()).toMatchObject({
        registerPath,
        signInPath,
      });
    });
  });

  describe('when user deletes a comment', () => {
    const noteId = 'note-test-id';

    it('triggers destroyNoteMutation on confirming the deletion in modal', async () => {
      createComponent();

      confirmAction.mockResolvedValueOnce(true);

      findDesignNotes().at(0).vm.$emit('delete-note', { id: noteId });

      expect(confirmAction).toHaveBeenCalled();

      await waitForPromises();

      expect(destroyNoteSuccessMutationHandler).toHaveBeenCalledWith({
        input: {
          id: noteId,
        },
      });
    });

    it('emits `delete-note-error` event if destroyNoteMutation fails', async () => {
      createComponent({ destroyNoteMutationHandler: deleteMutationErrorHandler });
      confirmAction.mockResolvedValueOnce(true);

      findDesignNotes().at(0).vm.$emit('delete-note', { id: noteId });

      await waitForPromises();

      expect(wrapper.emitted()).toEqual({
        'delete-note-error': [[DELETE_NOTE_ERROR]],
      });
    });
  });
});
