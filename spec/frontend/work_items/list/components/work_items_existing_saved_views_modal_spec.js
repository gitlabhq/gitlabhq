import { GlModal, GlSearchBoxByType, GlLoadingIcon, GlIcon, GlLink } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import getNamespaceSavedViewsQuery from '~/work_items/list/graphql/work_item_saved_views_namespace.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { subscribeWithLimitEnforce } from 'ee_else_ce/work_items/list/utils';
import WorkItemsExistingSavedViewsModal from '~/work_items/list/components/work_items_existing_saved_views_modal.vue';
import { CREATED_DESC, BROWSE_SAVED_VIEWS_PAGE_SIZE } from '~/work_items/list/constants';
import { helpPagePath } from '~/helpers/help_page_helper';

jest.mock('ee_else_ce/work_items/list/utils', () => ({
  ...jest.requireActual('ee_else_ce/work_items/list/utils'),
  subscribeWithLimitEnforce: jest.fn().mockResolvedValue({
    data: {
      workItemSavedViewSubscribe: {
        errors: [],
      },
    },
  }),
}));

describe('WorkItemsExistingSavedViewsModal', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mockPush = jest.fn();
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
      updatedAt: '2026-04-08T09:50:54Z',
      author: {
        id: 'gid://gitlab/User/1',
      },
      lastUpdatedBy: {
        id: 'gid://gitlab/User/1',
      },
      userPermissions: {
        updateSavedView: true,
        deleteSavedView: true,
        updateSavedViewVisibility: true,
        __typename: 'SavedViewPermissions',
      },
    },
    {
      __typename: 'WorkItemSavedViewType',
      id: 'gid://gitlab/WorkItems::SavedViews::SavedView/2',
      name: 'Team View',
      description: 'Shared with the team',
      isPrivate: false,
      subscribed: false,
      filters: {},
      displaySettings: {},
      sort: CREATED_DESC,
      updatedAt: '2026-04-08T09:50:54Z',
      author: {
        id: 'gid://gitlab/User/1',
      },
      lastUpdatedBy: {
        id: 'gid://gitlab/User/1',
      },
      userPermissions: {
        updateSavedView: true,
        deleteSavedView: true,
        updateSavedViewVisibility: true,
        __typename: 'SavedViewPermissions',
      },
    },
  ];

  const defaultPageInfo = {
    __typename: 'PageInfo',
    hasNextPage: false,
    hasPreviousPage: false,
    startCursor: null,
    endCursor: null,
  };

  const savedViewsHandler = jest.fn().mockResolvedValue({
    data: {
      namespace: {
        __typename: 'Namespace',
        id: 'namespace',
        savedViews: {
          __typename: 'SavedViewConnection',
          nodes: mockSavedViewsData,
          pageInfo: defaultPageInfo,
        },
      },
    },
  });

  const emptySavedViewsHandler = jest.fn().mockResolvedValue({
    data: {
      namespace: {
        savedViews: {
          nodes: [],
          pageInfo: defaultPageInfo,
        },
      },
    },
  });

  const paginatedSavedViewsHandler = jest.fn().mockResolvedValue({
    data: {
      namespace: {
        __typename: 'Namespace',
        id: 'namespace',
        savedViews: {
          __typename: 'SavedViewConnection',
          nodes: mockSavedViewsData,
          pageInfo: {
            __typename: 'PageInfo',
            hasNextPage: true,
            hasPreviousPage: false,
            startCursor: 'cursor-start',
            endCursor: 'cursor-end',
          },
        },
      },
    },
  });

  const simulatedErrorHandler = jest.fn().mockRejectedValue(new Error('this is fine'));

  const createComponent = async ({
    props,
    provide = {},
    mockSavedViewsHandler = savedViewsHandler,
  } = {}) => {
    const apolloProvider = createMockApollo([[getNamespaceSavedViewsQuery, mockSavedViewsHandler]]);

    wrapper = shallowMountExtended(WorkItemsExistingSavedViewsModal, {
      apolloProvider,
      propsData: {
        show: true,
        fullPath: 'test-project-path',
        ...props,
      },
      provide: {
        canCreateSavedView: true,
        subscribedSavedViewLimit: 10,
        isGroup: true,
        ...provide,
      },
      mocks: {
        $router: {
          push: mockPush,
        },
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        GlModal,
      },
    });

    await waitForPromises();
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findNewViewButton = () => wrapper.findByTestId('new-view-button');
  const findSavedViewItems = () => wrapper.findAllByTestId('saved-view-item');
  const findSubscribedIcons = () => wrapper.findAllByTestId('subscribed-view-icon');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNoPermissionAlert = () => wrapper.findByTestId('no-permission-alert');
  const findLoadMoreButton = () => wrapper.findByTestId('load-more-button');
  const findWarningMessage = () => wrapper.find('.gl-bg-orange-50');
  const findWarningIcon = () => findWarningMessage().findComponent(GlIcon);
  const findLearnMoreLink = () => findWarningMessage().findComponent(GlLink);

  beforeEach(async () => {
    await createComponent();
  });

  it('shows loading icon while saved views are loading', () => {
    createComponent();
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('fetches saved views with correct variables', () => {
    expect(savedViewsHandler).toHaveBeenCalledWith(
      expect.objectContaining({
        sort: 'NAME_ASC',
        subscribedOnly: false,
        fullPath: 'test-project-path',
        first: BROWSE_SAVED_VIEWS_PAGE_SIZE,
      }),
    );
  });

  it('does not fetch saved views when modal is hidden', async () => {
    savedViewsHandler.mockClear();
    await createComponent({ props: { show: false } });

    expect(savedViewsHandler).not.toHaveBeenCalled();
  });

  it('focuses the search input on showing modal', async () => {
    const focusSpy = jest.fn();
    findSearch().element.focus = focusSpy;

    findModal().vm.$emit('shown');
    await waitForPromises();
    expect(focusSpy).toHaveBeenCalled();
  });

  it('clears search input on hiding the modal', async () => {
    findSearch().vm.$emit('input', 'team');
    await waitForPromises();

    expect(findSearch().props('value')).toBe('team');
    findModal().vm.$emit('hide');

    await waitForPromises();
    expect(findSearch().props('value')).toBe('');
  });

  describe('saved view list', () => {
    it('correctly renders the saved views list', () => {
      expect(findSavedViewItems()).toHaveLength(mockSavedViewsData.length);

      mockSavedViewsData.forEach((view) => {
        expect(wrapper.text()).toContain(view.name);
        expect(wrapper.text()).toContain(view.description);
      });
    });

    it('shows "Added" and check icon only for subscribed views', async () => {
      await waitForPromises();

      expect(wrapper.text()).toContain('Added');
      expect(findSubscribedIcons()).toHaveLength(1);
    });

    it('navigates immediately to view if user is already subscribed', async () => {
      const firstView = findSavedViewItems().at(0);

      await firstView.trigger('click');
      await nextTick();

      expect(subscribeWithLimitEnforce).not.toHaveBeenCalled();

      expect(mockPush).toHaveBeenCalledWith({
        name: 'savedView',
        params: { view_id: '1' },
      });
    });

    it('subscribes then navigates to view when user is not subscribed', async () => {
      const secondView = findSavedViewItems().at(1);

      await secondView.trigger('click');
      await nextTick();

      expect(subscribeWithLimitEnforce).toHaveBeenCalled();
      await waitForPromises();

      expect(mockPush).toHaveBeenCalledWith({
        name: 'savedView',
        params: { view_id: '2' },
      });
    });
  });

  describe('search filtering', () => {
    it('filters views by name or description', async () => {
      findSearch().vm.$emit('input', 'team');
      await waitForPromises();

      expect(savedViewsHandler).toHaveBeenCalledWith(expect.objectContaining({ search: 'team' }));
    });

    it('shows "No results found" when server returns no matches for search term', async () => {
      const noResultsHandler = jest.fn().mockImplementation(({ search }) => {
        if (search) {
          return Promise.resolve({
            data: {
              namespace: {
                __typename: 'Namespace',
                id: 'namespace',
                savedViews: {
                  __typename: 'SavedViewConnection',
                  nodes: [],
                  pageInfo: defaultPageInfo,
                },
              },
            },
          });
        }
        return Promise.resolve({
          data: {
            namespace: {
              __typename: 'Namespace',
              id: 'namespace',
              savedViews: {
                __typename: 'SavedViewConnection',
                nodes: mockSavedViewsData,
                pageInfo: defaultPageInfo,
              },
            },
          },
        });
      });

      await createComponent({ mockSavedViewsHandler: noResultsHandler });

      findSearch().vm.$emit('input', 'foo');

      await waitForPromises();

      expect(wrapper.text()).toContain('No results found');
      expect(wrapper.text()).toContain('Edit your search and try again.');
      expect(findSavedViewItems()).toHaveLength(0);
    });
  });

  describe('pagination', () => {
    describe('when there is a next page', () => {
      beforeEach(async () => {
        await createComponent({ mockSavedViewsHandler: paginatedSavedViewsHandler });
      });

      it('renders a load more button at the end of the list', () => {
        expect(findLoadMoreButton().exists()).toBe(true);
      });

      it('shows a loading spinner while fetching the next page', async () => {
        findLoadMoreButton().vm.$emit('click');

        await nextTick();

        expect(findLoadingIcon().exists()).toBe(true);
      });

      it('calls fetchMore with the end cursor when load more button is clicked', async () => {
        await findLoadMoreButton().vm.$emit('click');

        await waitForPromises();

        expect(paginatedSavedViewsHandler).toHaveBeenCalledWith({
          after: 'cursor-end',
          first: 100,
          fullPath: 'test-project-path',
          search: undefined,
          sort: 'NAME_ASC',
          subscribedOnly: false,
        });
      });
    });

    describe('when there is no next page', () => {
      it('does not render a load more button', () => {
        expect(findLoadMoreButton().exists()).toBe(false);
      });
    });
  });

  describe('when there are no saved views available', () => {
    beforeEach(async () => {
      await createComponent({
        mockSavedViewsHandler: emptySavedViewsHandler,
      });
    });

    it('hides the search input', () => {
      expect(findSearch().exists()).toBe(false);
    });

    it('renders empty state and redirects to New View Modal', async () => {
      expect(wrapper.text()).toContain('No views yet');
      expect(findNewViewButton().exists()).toBe(true);

      findNewViewButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('hide')).toEqual([[false]]);
      expect(wrapper.emitted('show-new-view-modal')).toEqual([[]]);
    });
  });

  describe('when there is an error', () => {
    beforeEach(async () => {
      await createComponent({
        mockSavedViewsHandler: simulatedErrorHandler,
      });
    });

    it('hides the search input', () => {
      expect(findSearch().exists()).toBe(false);
    });

    it('renders empty state and redirects to New View Modal', async () => {
      expect(wrapper.text()).toContain('No views yet');
      expect(findNewViewButton().exists()).toBe(true);

      findNewViewButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('hide')).toEqual([[false]]);
      expect(wrapper.emitted('show-new-view-modal')).toEqual([[]]);
    });
  });

  describe('subscription limit warning', () => {
    describe('when showSubscriptionLimitWarning is false', () => {
      it('does not show the warning message', async () => {
        await createComponent({ props: { showSubscriptionLimitWarning: false } });

        expect(findWarningMessage().exists()).toBe(false);
      });
    });

    describe('when showSubscriptionLimitWarning is true', () => {
      beforeEach(async () => {
        await createComponent({ props: { showSubscriptionLimitWarning: true } });
      });

      it('shows the warning message with icon and link', () => {
        expect(findWarningMessage().exists()).toBe(true);
        expect(findWarningIcon().props('name')).toBe('warning');
        expect(findLearnMoreLink().exists()).toBe(true);
        expect(findLearnMoreLink().attributes('href')).toBe(
          helpPagePath('user/work_items/saved_views.md', { anchor: 'saved-view-limits' }),
        );
      });

      it('contains the correct warning text', () => {
        expect(findWarningMessage().text()).toContain(
          'You have reached the maximum number of views in your list.',
        );
        expect(findWarningMessage().text()).toContain(
          'If you add a view, the last view in your list will be removed.',
        );
      });
    });
  });

  describe('permissions', () => {
    it('hides empty state button when user cannot create saved view', async () => {
      await createComponent({
        provide: { canCreateSavedView: false },
        mockSavedViewsHandler: emptySavedViewsHandler,
      });

      expect(findNewViewButton().exists()).toBe(false);
    });

    describe('when user cannot create saved views and views exist', () => {
      beforeEach(async () => {
        await createComponent({ provide: { canCreateSavedView: false } });
      });

      it('shows no-permission alert', () => {
        expect(findNoPermissionAlert().exists()).toBe(true);
      });

      it.each`
        isGroup  | namespaceType
        ${true}  | ${'group'}
        ${false} | ${'project'}
      `(
        'shows $namespaceType namespace type in the alert message',
        async ({ isGroup, namespaceType }) => {
          await createComponent({ provide: { canCreateSavedView: false, isGroup } });

          expect(findNoPermissionAlert().text()).toContain(
            `You don't have permission to create views in this ${namespaceType}`,
          );
        },
      );
    });

    describe('when user cannot create saved views and no views exist', () => {
      it('does not show no-permission alert', async () => {
        await createComponent({
          provide: { canCreateSavedView: false },
          mockSavedViewsHandler: emptySavedViewsHandler,
        });

        expect(findNoPermissionAlert().exists()).toBe(false);
      });

      it.each`
        isGroup  | namespaceType
        ${true}  | ${'group'}
        ${false} | ${'project'}
      `(
        'shows $namespaceType namespace type in the empty state description',
        async ({ isGroup, namespaceType }) => {
          await createComponent({
            provide: { canCreateSavedView: false, isGroup },
            mockSavedViewsHandler: emptySavedViewsHandler,
          });

          expect(wrapper.text()).toContain(
            `You don't have permission to create views in this ${namespaceType}`,
          );
        },
      );
    });

    describe('when user can create saved views', () => {
      it('does not show no-permission alert even when views exist', () => {
        expect(findNoPermissionAlert().exists()).toBe(false);
      });
    });
  });
});
