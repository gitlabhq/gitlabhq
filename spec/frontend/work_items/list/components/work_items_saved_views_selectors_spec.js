import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsSavedViewsSelectors from '~/work_items/list/components/work_items_saved_views_selectors.vue';
import WorkItemsCreateSavedViewDropdown from '~/work_items/list/components/work_items_create_saved_view_dropdown.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { CREATED_DESC } from '~/work_items/list/constants';
import { ROUTES } from '~/work_items/constants';

describe('WorkItemsSavedViewsSelectors', () => {
  let wrapper;
  let routerPushMock;
  let toastShowMock;
  let mutateMock;

  const mockSavedViewsData = [
    {
      __typename: 'WorkItemSavedViewType',
      id: 'gid://gitlab/WorkItems::SavedViews::SavedView/1',
      name: 'My Private View',
      description: 'Only I can see this',
      isPrivate: true,
      subscribed: true,
      filters: {},
      displaySettings: {},
      sort: CREATED_DESC,
      userPermissions: {
        updateSavedView: true,
        deleteSavedView: true,
      },
    },
    {
      __typename: 'WorkItemSavedViewType',
      id: 'gid://gitlab/WorkItems::SavedViews::SavedView/2',
      name: 'Team View 1',
      description: 'Only I can see this',
      isPrivate: false,
      subscribed: true,
      filters: {},
      displaySettings: {},
      sort: CREATED_DESC,
      userPermissions: {
        updateSavedView: true,
        deleteSavedView: true,
      },
    },
    {
      __typename: 'WorkItemSavedViewType',
      id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3',
      name: 'Second Team View 2',
      description: 'Only I can see this',
      isPrivate: false,
      subscribed: true,
      filters: {},
      displaySettings: {},
      sort: CREATED_DESC,
      userPermissions: {
        updateSavedView: true,
        deleteSavedView: true,
      },
    },
  ];

  const mockUnsubscribeResponse = {
    data: {
      unsubscribeFromSavedView: {
        errors: [],
        savedView: {
          id: 'gid://gitlab/WorkItems::SavedViews::SavedView/1',
        },
      },
    },
  };

  const mockDeleteResponse = {
    data: {
      workItemSavedViewDelete: {
        errors: [],
        savedView: {
          id: 'gid://gitlab/WorkItems::SavedViews::SavedView/1',
        },
      },
    },
  };

  const createComponent = ({
    props,
    mockSavedViews = mockSavedViewsData,
    visibleViews = mockSavedViews.slice(0, 2),
    overflowedViews = mockSavedViews.slice(2),
    routeMock = { params: { view_id: '1' } },
    mutateResult = mockUnsubscribeResponse,
    subscribedSavedViewLimit = null,
  } = {}) => {
    routerPushMock = jest.fn();
    toastShowMock = jest.fn();
    mutateMock = jest.fn().mockResolvedValue(mutateResult);

    wrapper = shallowMountExtended(WorkItemsSavedViewsSelectors, {
      propsData: {
        fullPath: 'test-project-path',
        savedViews: mockSavedViews,
        sortKey: CREATED_DESC,
        filters: {},
        displaySettings: {},
        ...props,
      },
      data() {
        return {
          visibleViews,
          overflowedViews,
        };
      },
      provide: {
        subscribedSavedViewLimit,
      },
      slots: {
        'header-area': '<div data-testid="header-area-slot">Header Area</div>',
      },
      mocks: {
        $route: routeMock,
        $router: {
          push: routerPushMock,
        },
        $toast: {
          show: toastShowMock,
        },
        $apollo: {
          mutate: mutateMock,
        },
      },
      stubs: {
        WorkItemsSavedViewSelector: {
          props: ['savedView'],
          template: `
            <div data-testid="saved-view">
              <button data-testid="unsubscribe-btn" @click="$emit('unsubscribe-saved-view', savedView)">Unsubscribe</button>
              <button data-testid="delete-btn" @click="$emit('delete-saved-view', savedView)">Delete</button>
              {{ savedView.name }}
            </div>
          `,
        },
      },
    });
  };

  const findDefaultViewSelector = () => wrapper.findByTestId('saved-views-default-view-selector');
  const findVisibleViewSelectors = () => wrapper.findAllByTestId('visible-view-selector');
  const findOverflowDropdown = () => wrapper.findByTestId('saved-views-more-toggle');
  const findUnsubscribeBtnAt = (index) =>
    findVisibleViewSelectors().at(index).find('[data-testid="unsubscribe-btn"]');
  const findDeleteBtnAt = (index) =>
    findVisibleViewSelectors().at(index).find('[data-testid="delete-btn"]');
  const findCreateSavedViewDropdown = () => wrapper.findComponent(WorkItemsCreateSavedViewDropdown);

  describe('default view selector', () => {
    it('renders the default view selector title', () => {
      createComponent();

      expect(findDefaultViewSelector().text()).toBe('All items');
    });

    it('emits reset-to-default-view when clicked', async () => {
      createComponent();

      await findDefaultViewSelector().trigger('click');

      expect(wrapper.emitted('reset-to-default-view')).toHaveLength(1);
    });
  });

  describe('views selectors', () => {
    it('renders visible saved views', () => {
      createComponent();

      mockSavedViewsData.slice(0, 2).forEach((view) => {
        expect(wrapper.text()).toContain(view.name);
      });
    });

    it('renders the overflow dropdown when overflowed views exist', () => {
      createComponent();

      expect(findOverflowDropdown().exists()).toBe(true);
      expect(findVisibleViewSelectors()).toHaveLength(2);
    });

    it('does not render the overflow dropdown when no overflowed views exist', () => {
      createComponent({
        mockSavedViews: [mockSavedViewsData[0], mockSavedViewsData[1]],
        visibleViews: [mockSavedViewsData[0], mockSavedViewsData[1]],
        overflowedViews: [],
      });

      expect(findOverflowDropdown().exists()).toBe(false);
    });

    describe('overflow view click', () => {
      it('navigates to clicked overflow view', () => {
        createComponent();

        const overflowItems = findOverflowDropdown().props('items');

        overflowItems[0].action();

        expect(routerPushMock).toHaveBeenCalledWith({
          name: ROUTES.savedView,
          params: { view_id: '3' },
          query: undefined,
        });
      });
    });
  });

  describe('unsubscribe from saved view', () => {
    it('calls unsubscribe mutation when unsubscribe-saved-view event is emitted', async () => {
      createComponent();

      await findUnsubscribeBtnAt(0).trigger('click');
      await waitForPromises();

      expect(mutateMock).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              id: mockSavedViewsData[0].id,
            },
          },
        }),
      );
    });

    it('navigates to next view after successful unsubscribe', async () => {
      createComponent();

      await findUnsubscribeBtnAt(0).trigger('click');
      await waitForPromises();

      expect(routerPushMock).toHaveBeenCalledWith({
        name: ROUTES.savedView,
        params: { view_id: '2' },
      });
    });

    it('shows success toast after successful unsubscribe', async () => {
      createComponent();

      await findUnsubscribeBtnAt(0).trigger('click');
      await waitForPromises();

      expect(toastShowMock).toHaveBeenCalledWith('View removed from your list');
    });

    it('emits reset-to-default-view when unsubscribing from the last view', async () => {
      createComponent({
        mockSavedViews: [mockSavedViewsData[0]],
        visibleViews: [mockSavedViewsData[0]],
        overflowedViews: [],
      });

      await findUnsubscribeBtnAt(0).trigger('click');
      await waitForPromises();

      expect(wrapper.emitted('reset-to-default-view')).toHaveLength(1);
    });

    it('emits error event when unsubscribe mutation fails', async () => {
      createComponent();

      const networkError = new Error('Network error');
      mutateMock.mockRejectedValueOnce(networkError);

      await findUnsubscribeBtnAt(0).trigger('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
      expect(wrapper.emitted('error')[0]).toEqual([
        networkError,
        'An error occurred while removing the view. Please try again.',
      ]);
    });

    it('navigates to previous view when unsubscribing from the last view in list', async () => {
      createComponent({
        mockSavedViews: [mockSavedViewsData[0], mockSavedViewsData[1]],
        visibleViews: [mockSavedViewsData[0], mockSavedViewsData[1]],
        overflowedViews: [],
      });

      await findUnsubscribeBtnAt(1).trigger('click');
      await waitForPromises();

      expect(routerPushMock).toHaveBeenCalledWith({
        name: ROUTES.savedView,
        params: { view_id: '1' },
      });
    });
  });

  describe('delete saved view', () => {
    it('calls delete mutation when delete-saved-view event is emitted', async () => {
      createComponent({ mutateResult: mockDeleteResponse });

      await findDeleteBtnAt(0).trigger('click');
      await waitForPromises();

      expect(mutateMock).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              id: mockSavedViewsData[0].id,
            },
          },
        }),
      );
    });

    it('navigates to next view after successful delete', async () => {
      createComponent({ mutateResult: mockDeleteResponse });

      await findDeleteBtnAt(0).trigger('click');
      await waitForPromises();

      expect(routerPushMock).toHaveBeenCalledWith({
        name: ROUTES.savedView,
        params: { view_id: '2' },
      });
    });

    it('shows success toast after successful delete', async () => {
      createComponent({ mutateResult: mockDeleteResponse });

      await findDeleteBtnAt(0).trigger('click');
      await waitForPromises();

      expect(toastShowMock).toHaveBeenCalledWith('View has been deleted');
    });

    it('emits reset-to-default-view when deleting the last view', async () => {
      createComponent({
        mockSavedViews: [mockSavedViewsData[0]],
        visibleViews: [mockSavedViewsData[0]],
        overflowedViews: [],
        mutateResult: mockDeleteResponse,
      });

      await findDeleteBtnAt(0).trigger('click');
      await waitForPromises();

      expect(wrapper.emitted('reset-to-default-view')).toHaveLength(1);
    });

    it('emits error event when delete mutation fails', async () => {
      createComponent({ mutateResult: mockDeleteResponse });

      const networkError = new Error('Network error');
      mutateMock.mockRejectedValueOnce(networkError);

      await findDeleteBtnAt(0).trigger('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
      expect(wrapper.emitted('error')[0]).toEqual([
        networkError,
        'An error occurred while deleting the view. Please try again.',
      ]);
    });

    it('navigates to previous view when deleting the last view in list', async () => {
      createComponent({
        mockSavedViews: [mockSavedViewsData[0], mockSavedViewsData[1]],
        visibleViews: [mockSavedViewsData[0], mockSavedViewsData[1]],
        overflowedViews: [],
        mutateResult: mockDeleteResponse,
      });

      await findDeleteBtnAt(1).trigger('click');
      await waitForPromises();

      expect(routerPushMock).toHaveBeenCalledWith({
        name: ROUTES.savedView,
        params: { view_id: '1' },
      });
    });
  });

  describe('subscription limit warning', () => {
    it('passes showSubscriptionLimitWarning as false when below limit', () => {
      createComponent({ subscribedSavedViewLimit: 5 });

      expect(findCreateSavedViewDropdown().props('showSubscriptionLimitWarning')).toBe(false);
    });

    it('passes showSubscriptionLimitWarning as true when at limit', () => {
      createComponent({ subscribedSavedViewLimit: 3 });

      expect(findCreateSavedViewDropdown().props('showSubscriptionLimitWarning')).toBe(true);
    });

    it('passes showSubscriptionLimitWarning as true when exceeding limit', () => {
      createComponent({ subscribedSavedViewLimit: 2 });

      expect(findCreateSavedViewDropdown().props('showSubscriptionLimitWarning')).toBe(true);
    });

    it('passes correct fullPath and sortKey props to dropdown', () => {
      createComponent();

      expect(findCreateSavedViewDropdown().props('fullPath')).toBe('test-project-path');
      expect(findCreateSavedViewDropdown().props('sortKey')).toBe(CREATED_DESC);
    });
  });

  describe('header slot', () => {
    it('renders the header-area slot content', () => {
      createComponent();

      expect(wrapper.findByTestId('header-area-slot').exists()).toBe(true);
    });
  });
});
