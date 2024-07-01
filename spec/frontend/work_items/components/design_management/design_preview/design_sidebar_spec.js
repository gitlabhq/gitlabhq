import { GlSkeletonLoader, GlEmptyState, GlAccordionItem } from '@gitlab/ui';
import emptyDiscussionUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DesignSidebar from '~/work_items/components/design_management/design_preview/design_sidebar.vue';
import DesignDescription from '~/work_items/components/design_management/design_preview/design_description.vue';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';
import DesignDiscussion from '~/work_items/components/design_management/design_notes/design_discussion.vue';
import mockDesign from './mock_design';

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
  const findUnresolvedDiscussions = () => wrapper.findAllByTestId('unresolved-discussion');
  const findResolvedDiscussions = () => wrapper.findAllByTestId('resolved-discussion');
  const findUnresolvedDiscussionsCount = () => wrapper.findByTestId('unresolved-discussion-count');
  const findResolvedCommentsToggle = () => wrapper.findComponent(GlAccordionItem);

  function createComponent({ design = mockDesign, isLoading = false, isLoggedIn = true } = {}) {
    if (isLoggedIn) {
      window.gon.current_user_id = 1;
    }
    wrapper = shallowMountExtended(DesignSidebar, {
      propsData: {
        design,
        isLoading,
        isOpen: true,
      },
      mocks: {
        $route,
      },
    });
  }

  beforeEach(() => {
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
  });
});
