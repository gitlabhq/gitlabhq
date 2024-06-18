import { GlAccordionItem, GlEmptyState } from '@gitlab/ui';
import { nextTick } from 'vue';
import emptyDiscussionUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DesignDiscussion from '~/design_management/components/design_notes/design_discussion.vue';
import DesignNoteSignedOut from '~/design_management/components/design_notes/design_note_signed_out.vue';
import DesignSidebar from '~/design_management/components/design_sidebar.vue';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';
import DescriptionForm from '~/design_management/components/design_description/description_form.vue';
import updateActiveDiscussionMutation from '~/design_management/graphql/mutations/update_active_discussion.mutation.graphql';
import design from '../mock_data/design';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

const updateActiveDiscussionMutationVariables = {
  mutation: updateActiveDiscussionMutation,
  variables: {
    id: design.discussions.nodes[0].notes.nodes[0].id,
    source: 'discussion',
  },
};

const $route = {
  params: {
    id: '1',
  },
};

const mockDesignVariables = {
  fullPath: 'project-path',
  iid: '1',
  filenames: ['gid:/gitlab/Design/1'],
  atVersion: null,
};

const mutate = jest.fn().mockResolvedValue();

describe('Design management design sidebar component', () => {
  let wrapper;

  const findDiscussions = () => wrapper.findAllComponents(DesignDiscussion);
  const findDisclosure = () => wrapper.findAllComponents(DesignDisclosure);
  const findFirstDiscussion = () => findDiscussions().at(0);
  const findUnresolvedDiscussions = () => wrapper.findAllByTestId('unresolved-discussion');
  const findResolvedDiscussions = () => wrapper.findAllByTestId('resolved-discussion');
  const findResolvedCommentsToggle = () => wrapper.findComponent(GlAccordionItem);
  const findDescriptionForm = () => wrapper.findComponent(DescriptionForm);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findUnresolvedDiscussionsCount = () => wrapper.findByTestId('unresolved-discussion-count');

  function createComponent(props = {}) {
    wrapper = shallowMountExtended(DesignSidebar, {
      propsData: {
        design,
        resolvedDiscussionsExpanded: false,
        markdownPreviewPath: 'markdown/path',
        isLoading: false,
        designVariables: mockDesignVariables,
        isOpen: true,
        ...props,
      },
      mocks: {
        $route,
        $apollo: {
          mutate,
        },
      },
      provide: {
        registerPath: '/users/sign_up?redirect_to_referer=yes',
        signInPath: '/users/sign_in?redirect_to_referer=yes',
      },
    });
  }

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
  });

  it('renders disclosure', () => {
    createComponent();

    expect(findDisclosure().exists()).toBe(true);
  });

  describe('description form', () => {
    it('does not render when loading', () => {
      createComponent({ isLoading: true });

      expect(findDescriptionForm().exists()).toBe(false);
    });

    it('renders with default props', () => {
      createComponent();

      expect(findDescriptionForm().props()).toMatchObject({
        design,
        markdownPreviewPath: 'markdown/path',
        designVariables: mockDesignVariables,
      });
    });

    it('renders when there is permission but description is empty', () => {
      createComponent({
        design: { ...design, description: '', descriptionHtml: '' },
      });

      expect(findDescriptionForm().exists()).toBe(true);
    });

    it('renders when there is description but no permission', () => {
      createComponent({
        design: { ...design, issue: { userPermissions: { updateDesign: false } } },
      });

      expect(findDescriptionForm().exists()).toBe(true);
    });

    it('does not render when there is no permission and description is empty', () => {
      createComponent({
        design: {
          ...design,
          description: '',
          descriptionHtml: '',
          issue: { userPermissions: { updateDesign: false } },
        },
      });

      expect(findDescriptionForm().exists()).toBe(false);
    });
  });

  describe('when has no discussions', () => {
    beforeEach(() => {
      createComponent({
        design: {
          ...design,
          discussions: {
            nodes: [],
          },
        },
      });
    });

    it('does not render discussions', () => {
      expect(findDiscussions().exists()).toBe(false);
    });

    it('renders a message about possibility to create a new discussion', () => {
      const emptyState = findEmptyState();
      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props('svgPath')).toBe(emptyDiscussionUrl);
      expect(emptyState.text()).toBe(`Click on the image where you'd like to add a new comment.`);
    });

    it('renders 0 Threads for unresolved discussions', () => {
      expect(findUnresolvedDiscussionsCount().exists()).toBe(true);
      expect(findUnresolvedDiscussionsCount().text()).toBe('0 Threads');
    });
  });

  describe('when has discussions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correct amount of unresolved discussions', () => {
      expect(findUnresolvedDiscussions()).toHaveLength(1);
    });

    it('renders correct amount of resolved discussions', () => {
      expect(findResolvedDiscussions()).toHaveLength(1);
    });

    it('renders 1 Thread for unresolved discussions', () => {
      expect(findUnresolvedDiscussionsCount().exists()).toBe(true);
      expect(findUnresolvedDiscussionsCount().text()).toBe('1 Thread');
    });

    it('renders 2 Threads for unresolved discussions', () => {
      createComponent({
        design: {
          ...design,
          discussions: {
            nodes: [
              {
                id: 'discussion-id-1',
                resolved: false,
                notes: {
                  nodes: [
                    {
                      id: 'note-id-1',
                      author: {
                        id: 'gid://gitlab/User/1',
                      },
                    },
                  ],
                },
              },
              {
                id: 'discussion-id-2',
                resolved: false,
                notes: {
                  nodes: [
                    {
                      id: 'note-id-2',
                      author: {
                        id: 'gid://gitlab/User/1',
                      },
                    },
                  ],
                },
              },
            ],
          },
        },
      });

      expect(findUnresolvedDiscussionsCount().exists()).toBe(true);
      expect(findUnresolvedDiscussionsCount().text()).toBe('2 Threads');
    });

    it('has resolved comments accordion item collapsed', () => {
      expect(findResolvedCommentsToggle().props('visible')).toBe(false);
    });

    it('emits toggleResolveComments event on resolve comments button click', async () => {
      findResolvedCommentsToggle().vm.$emit('input', true);
      await nextTick();
      expect(wrapper.emitted('toggleResolvedComments')).toHaveLength(1);
    });

    it('opens the accordion item when resolvedDiscussionsExpanded prop changes to true', async () => {
      expect(findResolvedCommentsToggle().props('visible')).toBe(false);
      wrapper.setProps({
        resolvedDiscussionsExpanded: true,
      });
      await nextTick();
      expect(findResolvedCommentsToggle().props('visible')).toBe(true);
    });

    it('emits correct event to send a mutation to set an active discussion when clicking on a discussion', () => {
      findFirstDiscussion().vm.$emit('update-active-discussion');

      expect(mutate).toHaveBeenCalledWith(updateActiveDiscussionMutationVariables);
    });

    it('sends a mutation to reset an active discussion when clicking outside of discussion', () => {
      wrapper.find('.image-notes').trigger('click');

      expect(mutate).toHaveBeenCalledWith({
        ...updateActiveDiscussionMutationVariables,
        variables: { id: undefined, source: 'discussion' },
      });
    });

    it('emits correct event on discussion create note error', () => {
      findFirstDiscussion().vm.$emit('create-note-error', 'payload');
      expect(wrapper.emitted('onDesignDiscussionError')).toEqual([['payload']]);
    });

    it('emits correct event on discussion update note error', () => {
      findFirstDiscussion().vm.$emit('update-note-error', 'payload');
      expect(wrapper.emitted('updateNoteError')).toEqual([['payload']]);
    });

    it('emits correct event on discussion resolve error', () => {
      findFirstDiscussion().vm.$emit('resolve-discussion-error', 'payload');
      expect(wrapper.emitted('resolveDiscussionError')).toEqual([['payload']]);
    });

    it('changes prop correctly on opening discussion form', async () => {
      findFirstDiscussion().vm.$emit('open-form', 'some-id');

      await nextTick();
      expect(findFirstDiscussion().props('discussionWithOpenForm')).toBe('some-id');
    });
  });

  describe('when all discussions are resolved', () => {
    beforeEach(() => {
      createComponent({
        design: {
          ...design,
          discussions: {
            nodes: [
              {
                id: 'discussion-id',
                replyId: 'discussion-reply-id',
                resolved: true,
                notes: {
                  nodes: [
                    {
                      id: 'note-id',
                      body: '123',
                      author: {
                        name: 'Administrator',
                        username: 'root',
                        webUrl: 'link-to-author',
                        avatarUrl: 'link-to-avatar',
                      },
                    },
                  ],
                },
              },
            ],
          },
        },
      });
    });

    it('renders a message about possibility to create a new discussion', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not render unresolved discussions', () => {
      expect(findUnresolvedDiscussions()).toHaveLength(0);
    });
  });

  describe('when user is not logged in', () => {
    const findDesignNoteSignedOut = () => wrapper.findComponent(DesignNoteSignedOut);

    beforeEach(() => {
      window.gon = { current_user_id: null };
    });

    describe('design has no discussions', () => {
      beforeEach(() => {
        createComponent({
          design: {
            ...design,
            discussions: {
              nodes: [],
            },
          },
        });
      });

      it('does not render a message about possibility to create a new discussion', () => {
        expect(findEmptyState().exists()).toBe(false);
      });

      it('renders design-note-signed-out component', () => {
        expect(findDesignNoteSignedOut().exists()).toBe(true);
      });
    });

    describe('design has discussions', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders design-note-signed-out component', () => {
        expect(findDesignNoteSignedOut().exists()).toBe(true);
      });
    });
  });
});
