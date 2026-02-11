import { GlModal, GlSearchBoxByType, GlLoadingIcon, GlIcon, GlLink } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import getNamespaceSavedViewsQuery from '~/work_items/list/graphql/work_item_saved_views_namespace.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import subscribeToViewMutation from '~/work_items/graphql/subscribe_to_saved_view.mutation.graphql';
import WorkItemsExistingSavedViewsModal from '~/work_items/list/components/work_items_existing_saved_views_modal.vue';
import { CREATED_DESC } from '~/work_items/list/constants';

describe('WorkItemsExistingSavedViewsModal', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mockPush = jest.fn();
  const mockSavedViewsData = [
    {
      __typename: 'SavedView',
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
      __typename: 'SavedView',
      id: 'gid://gitlab/WorkItems::SavedViews::SavedView/2',
      name: 'Team View',
      description: 'Shared with the team',
      isPrivate: false,
      subscribed: false,
      filters: {},
      displaySettings: {},
      sort: CREATED_DESC,
      userPermissions: {
        updateSavedView: true,
        deleteSavedView: true,
      },
    },
  ];

  const mockSubscribeResponse = {
    data: {
      workItemSavedViewSubscribe: {
        __typename: 'WorkItemSavedViewSubscribePayload',
        errors: [],
        savedView: {
          __typename: 'WorkItemSavedViewType',
          id: 'gid://gitlab/WorkItems::SavedViews::SavedView/2',
        },
      },
    },
  };

  const savedViewsHandler = jest.fn().mockResolvedValue({
    data: {
      namespace: {
        __typename: 'Namespace',
        id: 'namespace',
        savedViews: {
          __typename: 'SavedViewConnection',
          nodes: mockSavedViewsData,
        },
      },
    },
  });

  const emptySavedViewsHandler = jest.fn().mockResolvedValue({
    data: {
      namespace: {
        savedViews: {
          nodes: [],
        },
      },
    },
  });

  const successSubscribeMutationHandler = jest.fn().mockResolvedValue(mockSubscribeResponse);

  const simulatedErrorHandler = jest.fn().mockRejectedValue(new Error('this is fine'));

  const createComponent = async ({
    props,
    mockSavedViewsHandler = savedViewsHandler,
    subscribeMutationHandler = successSubscribeMutationHandler,
  } = {}) => {
    const apolloProvider = createMockApollo([
      [getNamespaceSavedViewsQuery, mockSavedViewsHandler],
      [subscribeToViewMutation, subscribeMutationHandler],
    ]);

    wrapper = shallowMountExtended(WorkItemsExistingSavedViewsModal, {
      apolloProvider,
      propsData: {
        show: true,
        fullPath: 'test-project-path',
        ...props,
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

      expect(successSubscribeMutationHandler).not.toHaveBeenCalled();

      expect(mockPush).toHaveBeenCalledWith({
        name: 'savedView',
        params: { view_id: '1' },
      });
    });

    it('subscribes then navigates to view when user is not subscribed', async () => {
      const secondView = findSavedViewItems().at(1);

      await secondView.trigger('click');
      await nextTick();

      expect(successSubscribeMutationHandler).toHaveBeenCalled();
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

      expect(findSavedViewItems()).toHaveLength(1);
      expect(wrapper.text()).toContain('Team View');
      expect(wrapper.text()).not.toContain('My Private View');
    });

    it('shows "No results found" when there are no matches', async () => {
      findSearch().vm.$emit('input', 'foo');
      await waitForPromises();

      expect(wrapper.text()).toContain('No results found');
      expect(wrapper.text()).toContain('Edit your search and try again.');
      expect(findSavedViewItems()).toHaveLength(0);
    });
  });

  describe('when there are no saved views available', () => {
    beforeEach(() => {
      createComponent({
        mockSavedViewsHandler: emptySavedViewsHandler,
      });
    });

    it('disables the search input', () => {
      expect(findSearch().props('disabled')).toBe(true);
    });

    it('renders empty state and redirects to New View Modal', async () => {
      expect(wrapper.text()).toContain('No views currently exist');
      expect(findNewViewButton().exists()).toBe(true);

      findNewViewButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('hide')).toEqual([[false]]);
      expect(wrapper.emitted('show-new-view-modal')).toEqual([[]]);
    });
  });

  describe('when there is an error', () => {
    beforeEach(() => {
      createComponent({
        mockSavedViewsHandler: simulatedErrorHandler,
      });
    });

    it('disables the search input', () => {
      expect(findSearch().props('disabled')).toBe(true);
    });

    it('renders empty state and redirects to New View Modal', async () => {
      expect(wrapper.text()).toContain('No views currently exist');
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
});
