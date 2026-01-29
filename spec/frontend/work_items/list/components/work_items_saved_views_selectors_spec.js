import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsSavedViewsSelectors from '~/work_items/list/components/work_items_saved_views_selectors.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { CREATED_DESC } from '~/work_items/list/constants';

describe('WorkItemsSavedViewsSelectors', () => {
  let wrapper;

  const mockSavedViewsData = [
    {
      __typename: 'WorkItemSavedViewType',
      id: '1',
      name: 'My Private View',
      description: 'Only I can see this',
      isPrivate: true,
      subscribed: true,
      userPermissions: {
        updateSavedView: true,
      },
    },
    {
      __typename: 'WorkItemSavedViewType',
      id: '2',
      name: 'Team View 1',
      description: 'Only I can see this',
      isPrivate: false,
      subscribed: true,
      userPermissions: {
        updateSavedView: true,
      },
    },
    {
      __typename: 'WorkItemSavedViewType',
      id: '3',
      name: 'Second Team View 2',
      description: 'Only I can see this',
      isPrivate: false,
      subscribed: true,
      userPermissions: {
        updateSavedView: true,
      },
    },
  ];

  const createComponent = async ({ props, mockSavedViews = mockSavedViewsData } = {}) => {
    wrapper = shallowMountExtended(WorkItemsSavedViewsSelectors, {
      propsData: {
        fullPath: 'test-project-path',
        savedViews: mockSavedViews,
        sortKey: CREATED_DESC,
        ...props,
      },
      data() {
        return {
          subscribedSavedViews: mockSavedViews,
          visibleViews: mockSavedViews.slice(0, 2),
          overflowedViews: mockSavedViews.slice(2),
        };
      },
      slots: {
        'header-area': '<div data-testid="header-area-slot">Header Area</div>',
      },
      stubs: {
        WorkItemsSavedViewSelector: {
          props: ['savedView'],
          template: '<div data-testid="saved-view">{{ savedView.name}}</div>',
        },
      },
    });

    await waitForPromises();
  };
  const findDefaultViewSelector = () => wrapper.findByTestId('saved-views-default-view-selector');
  const findVisibleViewSelectors = () => wrapper.findAllByTestId('visible-view-selector');
  const findOverflowDropdown = () => wrapper.findByTestId('saved-views-more-toggle');

  describe('default view selector', () => {
    it('renders the default view selector title', () => {
      createComponent();
      expect(findDefaultViewSelector().text()).toBe('All items');
    });

    it('emits resets to defaults when clicked', async () => {
      createComponent();
      await findDefaultViewSelector().trigger('click');

      expect(wrapper.emitted('reset-to-default-view')).toHaveLength(1);
    });
  });

  describe('views selectors', () => {
    it('renders visible saved views', () => {
      createComponent();

      mockSavedViewsData.forEach((view, index) => {
        if (index < 2) expect(wrapper.text()).toContain(view.name);
      });
    });

    it('renders the overflow dropdown when overflowed views exist', () => {
      createComponent();

      expect(findOverflowDropdown().exists()).toBe(true);
      expect(findVisibleViewSelectors()).toHaveLength(2);
    });

    it('does not render the overflow dropdown when no overflowed views exist', () => {
      createComponent({ mockSavedViews: [mockSavedViewsData[0], mockSavedViewsData[1]] });

      expect(findOverflowDropdown().exists()).toBe(false);
    });
  });

  describe('header slot', () => {
    it('renders the header-area slot content', () => {
      createComponent();
      expect(wrapper.findByTestId('header-area-slot').exists()).toBe(true);
    });
  });
});
