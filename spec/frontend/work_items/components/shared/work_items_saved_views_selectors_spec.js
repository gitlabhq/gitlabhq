import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsSavedViewsSelectors from '~/work_items/components/shared/work_items_saved_views_selectors.vue';
import waitForPromises from 'helpers/wait_for_promises';
import getSubsribedSavedViewsQuery from '~/work_items/graphql/work_item_saved_views_namespace.query.graphql';

describe('WorkItemsSavedViewsSelectors', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mockSavedViewsData = [
    {
      __typename: 'SavedView',
      id: '1',
      name: 'My Private View',
      description: 'Only I can see this',
      isPrivate: true,
      isSubscribed: true,
    },
    {
      __typename: 'SavedView',
      id: '2',
      name: 'Team View 1',
      description: 'Only I can see this',
      isPrivate: false,
      isSubscribed: true,
    },
    {
      __typename: 'SavedView',
      id: '3',
      name: 'Second Team View 2',
      description: 'Only I can see this',
      isPrivate: false,
      isSubscribed: true,
    },
  ];

  const createComponent = async ({ props, mockSavedViews = mockSavedViewsData } = {}) => {
    const apolloProvider = createMockApollo();

    // TODO: to be removed when actual API is integrated
    apolloProvider.defaultClient.writeQuery({
      query: getSubsribedSavedViewsQuery,
      variables: {
        fullPath: 'test-project-path',
        subscribedOnly: false,
      },
      data: {
        namespace: {
          id: 'namespace',
          savedViews: {
            __typename: 'SavedViewConnection',
            nodes: mockSavedViews,
          },
        },
      },
    });

    wrapper = shallowMountExtended(WorkItemsSavedViewsSelectors, {
      apolloProvider,
      propsData: {
        fullPath: 'test-project-path',
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
