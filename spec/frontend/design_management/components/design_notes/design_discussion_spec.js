import { GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import DesignDiscussion from '~/design_management/components/design_notes/design_discussion.vue';
import DesignNote from '~/design_management/components/design_notes/design_note.vue';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import ToggleRepliesWidget from '~/design_management/components/design_notes/toggle_replies_widget.vue';
import createNoteMutation from '~/design_management/graphql/mutations/create_note.mutation.graphql';
import toggleResolveDiscussionMutation from '~/design_management/graphql/mutations/toggle_resolve_discussion.mutation.graphql';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import mockDiscussion from '../../mock_data/discussion';
import notes from '../../mock_data/notes';

const defaultMockDiscussion = {
  id: '0',
  resolved: false,
  resolvable: true,
  notes,
};

describe('Design discussions component', () => {
  let wrapper;

  const findDesignNotes = () => wrapper.findAll(DesignNote);
  const findReplyPlaceholder = () => wrapper.find(ReplyPlaceholder);
  const findReplyForm = () => wrapper.find(DesignReplyForm);
  const findRepliesWidget = () => wrapper.find(ToggleRepliesWidget);
  const findResolveButton = () => wrapper.find('[data-testid="resolve-button"]');
  const findResolveIcon = () => wrapper.find('[data-testid="resolve-icon"]');
  const findResolvedMessage = () => wrapper.find('[data-testid="resolved-message"]');
  const findResolveLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findResolveCheckbox = () => wrapper.find('[data-testid="resolve-checkbox"]');

  const mutationVariables = {
    mutation: createNoteMutation,
    variables: {
      input: {
        noteableId: 'noteable-id',
        body: 'test',
        discussionId: '0',
      },
    },
  };
  const mutate = jest.fn().mockResolvedValue({ data: { createNote: { errors: [] } } });
  const $apollo = {
    mutate,
  };

  function createComponent(props = {}, data = {}) {
    wrapper = mount(DesignDiscussion, {
      propsData: {
        resolvedDiscussionsExpanded: true,
        discussion: defaultMockDiscussion,
        noteableId: 'noteable-id',
        designId: 'design-id',
        discussionIndex: 1,
        discussionWithOpenForm: '',
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
        $apollo,
        $route: {
          hash: '#note_1',
        },
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when discussion is not resolvable', () => {
    beforeEach(() => {
      createComponent({
        discussion: {
          ...defaultMockDiscussion,
          resolvable: false,
        },
      });
    });

    it('does not render an icon to resolve a thread', () => {
      expect(findResolveIcon().exists()).toBe(false);
    });

    it('does not render a checkbox in reply form', () => {
      findReplyPlaceholder().vm.$emit('focus');

      return wrapper.vm.$nextTick().then(() => {
        expect(findResolveCheckbox().exists()).toBe(false);
      });
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

    it('does not render toggle replies widget', () => {
      expect(findRepliesWidget().exists()).toBe(false);
    });

    it('renders a correct icon to resolve a thread', () => {
      expect(findResolveIcon().props('name')).toBe('check-circle');
    });

    it('renders a checkbox with Resolve thread text in reply form', () => {
      findReplyPlaceholder().vm.$emit('focus');
      wrapper.setProps({ discussionWithOpenForm: defaultMockDiscussion.id });

      return wrapper.vm.$nextTick().then(() => {
        expect(findResolveCheckbox().text()).toBe('Resolve thread');
      });
    });

    it('does not render resolved message', () => {
      expect(findResolvedMessage().exists()).toBe(false);
    });
  });

  describe('when discussion is resolved', () => {
    beforeEach(() => {
      createComponent({
        discussion: {
          ...defaultMockDiscussion,
          resolved: true,
          resolvedBy: notes[0].author,
          resolvedAt: '2020-05-08T07:10:45Z',
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
      expect(findResolveIcon().props('name')).toBe('check-circle-filled');
    });

    describe('when replies are expanded', () => {
      beforeEach(() => {
        findRepliesWidget().vm.$emit('toggle');
        return wrapper.vm.$nextTick();
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

      it('renders a checkbox with Unresolve thread text in reply form', () => {
        findReplyPlaceholder().vm.$emit('focus');
        wrapper.setProps({ discussionWithOpenForm: defaultMockDiscussion.id });

        return wrapper.vm.$nextTick().then(() => {
          expect(findResolveCheckbox().text()).toBe('Unresolve thread');
        });
      });
    });
  });

  it('hides reply placeholder and opens form on placeholder click', () => {
    createComponent();
    findReplyPlaceholder().vm.$emit('focus');
    wrapper.setProps({ discussionWithOpenForm: defaultMockDiscussion.id });

    return wrapper.vm.$nextTick().then(() => {
      expect(findReplyPlaceholder().exists()).toBe(false);
      expect(findReplyForm().exists()).toBe(true);
    });
  });

  it('calls mutation on submitting form and closes the form', async () => {
    createComponent(
      { discussionWithOpenForm: defaultMockDiscussion.id },
      { discussionComment: 'test', isFormRendered: true },
    );

    findReplyForm().vm.$emit('submit-form');
    expect(mutate).toHaveBeenCalledWith(mutationVariables);

    await mutate();
    await wrapper.vm.$nextTick();

    expect(findReplyForm().exists()).toBe(false);
  });

  it('clears the discussion comment on closing comment form', () => {
    createComponent(
      { discussionWithOpenForm: defaultMockDiscussion.id },
      { discussionComment: 'test', isFormRendered: true },
    );

    return wrapper.vm
      .$nextTick()
      .then(() => {
        findReplyForm().vm.$emit('cancel-form');

        expect(wrapper.vm.discussionComment).toBe('');
        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(findReplyForm().exists()).toBe(false);
      });
  });

  describe('when any note from a discussion is active', () => {
    it.each([notes[0], notes[0].discussion.notes.nodes[1]])(
      'applies correct class to all notes in the active discussion',
      (note) => {
        createComponent(
          { discussion: mockDiscussion },
          {
            activeDiscussion: {
              id: note.id,
              source: 'pin',
            },
          },
        );

        expect(
          wrapper
            .findAll(DesignNote)
            .wrappers.every((designNote) => designNote.classes('gl-bg-blue-50')),
        ).toBe(true);
      },
    );
  });

  it('calls toggleResolveDiscussion mutation on resolve thread button click', () => {
    createComponent();
    findResolveButton().trigger('click');
    expect(mutate).toHaveBeenCalledWith({
      mutation: toggleResolveDiscussionMutation,
      variables: {
        id: defaultMockDiscussion.id,
        resolve: true,
      },
    });
    return wrapper.vm.$nextTick(() => {
      expect(findResolveLoadingIcon().exists()).toBe(true);
    });
  });

  it('calls toggleResolveDiscussion mutation after adding a note if checkbox was checked', () => {
    createComponent(
      { discussionWithOpenForm: defaultMockDiscussion.id },
      { discussionComment: 'test', isFormRendered: true },
    );
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

    expect(wrapper.emitted('open-form')).toBeTruthy();
  });
});
