import { GlLoadingIcon, GlFormCheckbox } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import DesignDiscussion from '~/design_management/components/design_notes/design_discussion.vue';
import DesignNote from '~/design_management/components/design_notes/design_note.vue';
import DesignNoteSignedOut from '~/design_management/components/design_notes/design_note_signed_out.vue';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import ToggleRepliesWidget from '~/design_management/components/design_notes/toggle_replies_widget.vue';
import toggleResolveDiscussionMutation from '~/design_management/graphql/mutations/toggle_resolve_discussion.mutation.graphql';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import destroyNoteMutation from '~/design_management/graphql/mutations/destroy_note.mutation.graphql';
import { DELETE_NOTE_ERROR_MSG } from '~/design_management/constants';
import mockDiscussion from '../../mock_data/discussion';
import notes from '../../mock_data/notes';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const defaultMockDiscussion = {
  id: '0',
  resolved: false,
  resolvable: true,
  notes,
};

describe('Design discussions component', () => {
  let wrapper;

  const findDesignNotesList = () => wrapper.find('[data-testid="design-discussion-content"]');
  const findDesignNotes = () => wrapper.findAllComponents(DesignNote);
  const findReplyPlaceholder = () => wrapper.findComponent(DiscussionReplyPlaceholder);
  const findReplyForm = () => wrapper.findComponent(DesignReplyForm);
  const findRepliesWidget = () => wrapper.findComponent(ToggleRepliesWidget);
  const findResolveButton = () => wrapper.find('[data-testid="resolve-button"]');
  const findResolvedMessage = () => wrapper.find('[data-testid="resolved-message"]');
  const findResolveLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findResolveCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const registerPath = '/users/sign_up?redirect_to_referer=yes';
  const signInPath = '/users/sign_in?redirect_to_referer=yes';
  const mutate = jest.fn().mockResolvedValue({ data: { createNote: { errors: [] } } });
  const readQuery = jest.fn().mockReturnValue({
    project: {
      issue: { designCollection: { designs: { nodes: [{ currentUserTodos: { nodes: [] } }] } } },
    },
  });
  const $apollo = {
    mutate,
    provider: { clients: { defaultClient: { readQuery } } },
  };

  function createComponent({ props = {}, data = {}, apolloConfig = {} } = {}) {
    wrapper = mount(DesignDiscussion, {
      propsData: {
        resolvedDiscussionsExpanded: true,
        discussion: defaultMockDiscussion,
        noteableId: 'noteable-id',
        designId: 'design-id',
        discussionIndex: 1,
        discussionWithOpenForm: '',
        registerPath,
        signInPath,
        ...props,
      },
      data() {
        return {
          ...data,
        };
      },
      provide: {
        projectPath: 'project-path',
        issueIid: '1',
      },
      mocks: {
        $apollo: {
          ...$apollo,
          ...apolloConfig,
        },
        $route: {
          hash: '#note_1',
          params: {
            id: 1,
          },
          query: {
            version: null,
          },
        },
      },
      stubs: {
        EmojiPicker: true,
      },
    });
  }

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
  });

  afterEach(() => {
    confirmAction.mockReset();
  });

  describe('when discussion is not resolvable', () => {
    beforeEach(() => {
      createComponent({
        props: {
          discussion: {
            ...defaultMockDiscussion,
            resolvable: false,
          },
        },
      });
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
  });

  describe('when discussion is resolved', () => {
    let dispatchEventSpy;

    beforeEach(() => {
      dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

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

    it('emit todo:toggle when discussion is resolved', async () => {
      createComponent({
        props: { discussionWithOpenForm: defaultMockDiscussion.id },
        data: { isFormRendered: true },
      });
      findResolveButton().trigger('click');
      findReplyForm().vm.$emit('submitForm');

      await mutate();
      await nextTick();

      const dispatchedEvent = dispatchEventSpy.mock.calls[0][0];

      expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
      expect(dispatchedEvent.detail).toEqual({ delta: 0 });
      expect(dispatchedEvent.type).toBe('todo:toggle');
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

  describe('when any note from a discussion is active', () => {
    it.each([notes[0], notes[0].discussion.notes.nodes[1]])(
      'applies correct class to the active discussion',
      (note) => {
        createComponent({
          props: { discussion: mockDiscussion },
          data: {
            activeDiscussion: {
              id: note.id,
              source: 'pin',
            },
          },
        });

        expect(findDesignNotesList().classes('gl-bg-blue-50')).toBe(true);
      },
    );
  });

  it('calls toggleResolveDiscussion mutation on resolve thread button click', async () => {
    createComponent();
    findResolveButton().trigger('click');
    expect(mutate).toHaveBeenCalledWith({
      mutation: toggleResolveDiscussionMutation,
      variables: {
        id: defaultMockDiscussion.id,
        resolve: true,
      },
    });
    await nextTick();
    expect(findResolveLoadingIcon().exists()).toBe(true);
  });

  it('calls toggleResolveDiscussion mutation after adding a note if checkbox was checked', () => {
    createComponent({
      props: { discussionWithOpenForm: defaultMockDiscussion.id },
      data: { isFormRendered: true },
    });
    findResolveButton().trigger('click');
    findReplyForm().vm.$emit('submitForm');

    return mutate().then(() => {
      expect(mutate).toHaveBeenCalledWith({
        mutation: toggleResolveDiscussionMutation,
        variables: {
          id: defaultMockDiscussion.id,
          resolve: true,
        },
      });
    });
  });

  it('emits openForm event on opening the form', () => {
    createComponent();
    findReplyPlaceholder().vm.$emit('focus');

    expect(wrapper.emitted('open-form')).toHaveLength(1);
  });

  describe('when user is not logged in', () => {
    const findDesignNoteSignedOut = () => wrapper.findComponent(DesignNoteSignedOut);

    beforeEach(() => {
      window.gon = { current_user_id: null };
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

  it('should open confirmation modal when the note emits `delete-note` event', () => {
    createComponent();

    findDesignNotes().at(0).vm.$emit('delete-note', { id: '1' });
    expect(confirmAction).toHaveBeenCalled();
  });

  describe('when confirmation modal is opened', () => {
    const noteId = 'note-test-id';

    it('sends the mutation with correct variables', async () => {
      confirmAction.mockResolvedValueOnce(true);
      const destroyNoteMutationSuccess = jest.fn().mockResolvedValue({
        data: { destroyNote: { note: null, __typename: 'DestroyNote', errors: [] } },
      });
      createComponent({ apolloConfig: { mutate: destroyNoteMutationSuccess } });

      findDesignNotes().at(0).vm.$emit('delete-note', { id: noteId });

      expect(confirmAction).toHaveBeenCalled();

      await waitForPromises();

      expect(destroyNoteMutationSuccess).toHaveBeenCalledWith({
        update: expect.any(Function),
        mutation: destroyNoteMutation,
        variables: {
          input: {
            id: noteId,
          },
        },
        optimisticResponse: {
          destroyNote: {
            note: null,
            errors: [],
            __typename: 'DestroyNotePayload',
          },
        },
      });
    });

    it('emits `delete-note-error` event if GraphQL mutation fails', async () => {
      confirmAction.mockResolvedValueOnce(true);
      const destroyNoteMutationError = jest.fn().mockRejectedValue(new Error('GraphQL error'));
      createComponent({ apolloConfig: { mutate: destroyNoteMutationError } });

      findDesignNotes().at(0).vm.$emit('delete-note', { id: noteId });

      await waitForPromises();

      expect(destroyNoteMutationError).toHaveBeenCalled();

      await waitForPromises();

      expect(wrapper.emitted()).toEqual({
        'delete-note-error': [[DELETE_NOTE_ERROR_MSG]],
      });
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
});
