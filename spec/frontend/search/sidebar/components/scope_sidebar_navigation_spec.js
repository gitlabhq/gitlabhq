import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import sidebarEventHub from '~/super_sidebar/event_hub';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { RECEIVE_NAVIGATION_COUNT } from '~/search/store/mutation_types';
import getBlobSearchCountQuery from '~/search/graphql/blob_search_zoekt_count_only.query.graphql';
import {
  MOCK_QUERY,
  MOCK_NAVIGATION,
  MOCK_NAVIGATION_ITEMS,
  mockgetBlobSearchCountQuery,
} from '../../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

describe('ScopeSidebarNavigation', () => {
  let wrapper;
  const mockError = new Error('Network error');

  const actionSpies = {
    fetchSidebarCount: jest.fn(),
  };

  const getterSpies = {
    navigationItems: jest.fn(() => MOCK_NAVIGATION_ITEMS),
  };

  const mutationSpies = {
    [RECEIVE_NAVIGATION_COUNT]: jest.fn(),
  };

  const blobCountHandler = jest.fn().mockResolvedValue(mockgetBlobSearchCountQuery);
  const mockQueryError = jest.fn().mockRejectedValue(mockError);

  const createComponent = (
    initialState,
    provide = { glFeatures: { workItemScopeFrontend: true } },
    gqlHandler = blobCountHandler,
  ) => {
    const requestHandlers = [[getBlobSearchCountQuery, gqlHandler]];
    const apolloProvider = createMockApollo(requestHandlers);
    const state = {
      urlQuery: MOCK_QUERY,
      navigation: MOCK_NAVIGATION,
      ...initialState,
    };

    const store = new Vuex.Store({
      state,
      actions: actionSpies,
      getters: getterSpies,
      mutations: mutationSpies,
    });

    wrapper = mount(ScopeSidebarNavigation, {
      apolloProvider,
      store,
      stubs: {
        NavItem,
      },
      provide,
    });
  };

  const findNavElement = () => wrapper.findComponent('nav');
  const findNavItems = () => wrapper.findAllComponents(NavItem);
  const findNavItemActive = () => wrapper.find('[aria-current=page]');
  const findNavItemActiveLabel = () =>
    findNavItemActive().find('[data-testid="nav-item-link-label"]');

  describe('when navigation render', () => {
    beforeEach(() => {
      jest.spyOn(sidebarEventHub, '$emit');
      createComponent({ urlQuery: { ...MOCK_QUERY, search: 'test' } });
    });

    it('renders section', () => {
      expect(findNavElement().exists()).toBe(true);
    });

    it('calls proper action when rendered', async () => {
      await nextTick();
      expect(actionSpies.fetchSidebarCount).toHaveBeenCalled();
    });

    it('renders all nav item components', () => {
      expect(findNavItems()).toHaveLength(14);
    });

    it('has all proper links', () => {
      const linkAtPosition = 3;
      const { link } = MOCK_NAVIGATION[Object.keys(MOCK_NAVIGATION)[linkAtPosition]];

      expect(findNavItems().at(linkAtPosition).findComponent('a').attributes('href')).toBe(link);
    });
  });

  describe('when scope navigation', () => {
    describe('when sets proper state with url scope set', () => {
      beforeEach(() => {
        const navigationItemsClone = [...MOCK_NAVIGATION_ITEMS];
        navigationItemsClone[3].is_active = false;
        navigationItemsClone[3].items[1].is_active = true;
        getterSpies.navigationItems = jest.fn(() => navigationItemsClone);

        createComponent();
      });

      it('has correct active item', () => {
        expect(findNavItemActive().exists()).toBe(true);
        expect(findNavItemActiveLabel().text()).toBe('Epics');
      });
    });

    describe('when sets proper state with Feature Flag off', () => {
      beforeEach(() => {
        const navigationItemsClone = [...MOCK_NAVIGATION_ITEMS];
        navigationItemsClone[3].is_active = true;

        getterSpies.navigationItems = jest.fn(() => navigationItemsClone);
        createComponent({}, { glFeatures: { workItemScopeFrontend: false } });
      });

      it('does not render work items subitems', () => {
        expect(findNavItemActive().exists()).toBe(true);
        expect(findNavItemActiveLabel().text()).toBe('Work items');
        expect(findNavItems()).toHaveLength(10);
      });
    });
  });

  describe('Zoekt graphql count', () => {
    beforeEach(() => {
      createComponent(
        {
          zoektAvailable: true,
          query: {
            search: 'test search',
            group_id: '123',
            regex: 'false',
          },
        },
        { glFeatures: { zoektMultimatchFrontend: true } },
      );
    });

    describe('when conditions are met', () => {
      it('makes graphql query with correct variables for group search', () => {
        expect(blobCountHandler).toHaveBeenCalledWith({
          search: 'test search',
          chunkCount: 5,
          groupId: 'gid://gitlab/Group/123',
          projectId: undefined,
          includeArchived: false,
          includeForked: false,
          regex: false,
        });
      });

      it('commits the count to store on successful response', async () => {
        await blobCountHandler();
        jest.runOnlyPendingTimers();
        await waitForPromises();

        expect(mutationSpies[RECEIVE_NAVIGATION_COUNT]).toHaveBeenCalledWith(expect.anything(), {
          key: 'blobs',
          count: '123',
        });
      });
    });

    describe('when conditions are not met', () => {
      describe('when group_id and project_id are missing', () => {
        beforeEach(() => {
          blobCountHandler.mockClear();
          createComponent(
            {
              zoektAvailable: true,
              query: {
                search: 'test',
                regex: 'false',
              },
            },
            { glFeatures: { zoektMultimatchFrontend: true } },
          );
        });

        it('does not make query', () => {
          expect(blobCountHandler).not.toHaveBeenCalled();
        });
      });

      describe('when zoektMultimatchFrontend feature is disabled', () => {
        beforeEach(() => {
          blobCountHandler.mockClear();
          createComponent(
            {
              zoektAvailable: true,
              query: {
                search: 'test',
                regex: 'false',
              },
            },
            { glFeatures: { zoektMultimatchFrontend: false } },
          );
        });

        it('does not make query', () => {
          expect(blobCountHandler).not.toHaveBeenCalled();
        });
      });

      describe('when zoektAvailable is false', () => {
        beforeEach(() => {
          blobCountHandler.mockClear();
          createComponent(
            {
              zoektAvailable: false,
              query: {
                search: 'test',
                regex: 'false',
              },
            },
            { glFeatures: { zoektMultimatchFrontend: true } },
          );
        });

        it('does not make query', () => {
          expect(blobCountHandler).not.toHaveBeenCalled();
        });
      });
    });

    describe('error handling', () => {
      beforeEach(async () => {
        jest.spyOn(Sentry, 'captureException').mockImplementation();
        createComponent(
          {
            zoektAvailable: true,
            query: {
              search: 'test search',
              group_id: '123',
              regex: 'false',
            },
          },
          { glFeatures: { zoektMultimatchFrontend: true } },
          mockQueryError,
        );
        jest.runOnlyPendingTimers();
        await waitForPromises();
      });

      it('captures exception in Sentry when query fails', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
      });
    });
  });
});
