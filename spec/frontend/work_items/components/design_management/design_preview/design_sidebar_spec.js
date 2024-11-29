import { GlSkeletonLoader, GlEmptyState, GlAccordionItem } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import emptyDiscussionUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import DesignSidebar from '~/work_items/components/design_management/design_preview/design_sidebar.vue';
import DesignDescription from '~/work_items/components/design_management/design_preview/design_description.vue';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';
import DesignDiscussion from '~/work_items/components/design_management/design_notes/design_discussion.vue';
import DesignNoteSignedOut from '~/work_items/components/design_management/design_notes/design_note_signed_out.vue';
import mockDesign from './mock_design';

jest.mock('~/lib/utils/common_utils');

Vue.use(VueApollo);

describe('DesignSidebar', () => {
  let wrapper;

  const $route = {
    params: {
      iid: '3',
      id: '1',
    },
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDisclosure = () => wrapper.findAllComponents(DesignDisclosure);
  const findDesignDescription = () => wrapper.findComponent(DesignDescription);
  const findDiscussions = () => wrapper.findAllComponents(DesignDiscussion);
  const findFirstDiscussion = () => findDiscussions().at(0);
  const findUnresolvedDiscussions = () => wrapper.findAllByTestId('unresolved-discussion');
  const findResolvedDiscussions = () => wrapper.findAllByTestId('resolved-discussion');
  const findUnresolvedDiscussionsCount = () => wrapper.findByTestId('unresolved-discussion-count');
  const findResolvedCommentsToggle = () => wrapper.findComponent(GlAccordionItem);
  const findDesignNoteSignedOut = () => wrapper.findComponent(DesignNoteSignedOut);

  const mockUpdateActiveDiscussionMutationResolver = jest.fn();
  const mockApollo = createMockApollo([], {
    Mutation: {
      updateActiveDesignDiscussion: mockUpdateActiveDiscussionMutationResolver,
    },
  });

  const mockDesignVariables = {
    fullPath: 'gitlab-org/gitlab-shell',
    iid: '1',
    filenames: ['image_name.png'],
    atVersion: null,
  };

  const createComponent = ({
    design = mockDesign,
    isLoading = false,
    resolvedDiscussionsExpanded = false,
    isCommentFormPresent = false,
  } = {}) => {
    wrapper = shallowMountExtended(DesignSidebar, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: mockApollo,
      propsData: {
        design,
        isLoading,
        designVariables: mockDesignVariables,
        isOpen: true,
        markdownPreviewPath: '/group/project/preview_markdown?target_type=WorkItem',
        resolvedDiscussionsExpanded,
        isCommentFormPresent,
      },
      mocks: {
        $route,
      },
      provide: {
        registerPath: '/users/sign_up?redirect_to_referer=yes',
        signInPath: '/users/sign_in?redirect_to_referer=yes',
      },
    });
  };

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
    createComponent();
  });

  it('renders disclosure', () => {
    expect(findDisclosure().exists()).toBe(true);
  });

  it('renders loading state when loading', () => {
    createComponent({ isLoading: true });
    expect(findEmptyState().exists()).toBe(false);
    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('renders design description', () => {
    expect(findDesignDescription().exists()).toBe(true);
    expect(findDesignDescription().props()).toMatchObject({
      design: mockDesign,
    });
  });

  describe('when has no discussions', () => {
    beforeEach(() => {
      createComponent({
        design: {
          ...mockDesign,
          discussions: {
            nodes: [],
          },
        },
      });
    });

    it('does not render discussions', () => {
      expect(findDiscussions().exists()).toBe(false);
    });

    it('renders empty state', () => {
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
          ...mockDesign,
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
      createComponent({ resolvedDiscussionsExpanded: true });
      await nextTick();
      expect(findResolvedCommentsToggle().props('visible')).toBe(true);
    });

    it('emits correct event to send a mutation to set an active discussion when clicking on a discussion', async () => {
      findFirstDiscussion().vm.$emit('update-active-discussion');
      await nextTick();

      expect(mockUpdateActiveDiscussionMutationResolver).toHaveBeenCalledWith(
        expect.any(Object),
        { id: mockDesign.discussions.nodes[0].notes.nodes[0].id, source: 'discussion' },
        expect.any(Object),
        expect.any(Object),
      );
    });

    it('sends a mutation to reset an active discussion when clicking outside of discussion', async () => {
      wrapper.find('.image-notes').trigger('click');
      await nextTick();

      expect(mockUpdateActiveDiscussionMutationResolver).toHaveBeenCalledWith(
        expect.any(Object),
        { id: undefined, source: 'discussion' },
        expect.any(Object),
        expect.any(Object),
      );
    });

    it('emits correct event on discussion create note error', () => {
      findFirstDiscussion().vm.$emit('create-note-error', 'payload');
      expect(wrapper.emitted('onDesignDiscussionError')).toEqual([['payload']]);
    });

    it('emits correct event on discussion update note error', () => {
      findFirstDiscussion().vm.$emit('update-note-error', 'payload');
      expect(wrapper.emitted('updateNoteError')).toEqual([['payload']]);

      findFirstDiscussion().vm.$emit('resolve-discussion-error', 'payload');
      expect(wrapper.emitted('resolveDiscussionError')).toEqual([['payload']]);
    });

    it('emits correct event on discussion resolve error', () => {
      findFirstDiscussion().vm.$emit('resolve-discussion-error', 'payload');
      expect(wrapper.emitted('resolveDiscussionError')).toEqual([['payload']]);
    });

    it('emits correct event on discussion delete note error', () => {
      findFirstDiscussion().vm.$emit('delete-note-error', 'payload');
      expect(wrapper.emitted('deleteNoteError')).toEqual([['payload']]);
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
          ...mockDesign,
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
    beforeEach(() => {
      isLoggedIn.mockReturnValue(false);
    });

    describe('design has no discussions', () => {
      beforeEach(() => {
        createComponent({
          design: {
            ...mockDesign,
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
