import { GlTab } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import OverviewTabs from '~/groups/components/overview_tabs.vue';
import GroupsApp from '~/groups/components/app.vue';
import GroupFolderComponent from '~/groups/components/group_folder.vue';
import SubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/subgroups_and_projects_empty_state.vue';
import SharedProjectsEmptyState from '~/groups/components/empty_states/shared_projects_empty_state.vue';
import InactiveProjectsEmptyState from '~/groups/components/empty_states/inactive_projects_empty_state.vue';
import GroupsStore from '~/groups/store/groups_store';
import GroupsService from '~/groups/service/groups_service';
import InactiveProjectsService from '~/groups/service/inactive_projects_service';
import { createRouter } from '~/groups/init_overview_tabs';
import eventHub from '~/groups/event_hub';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_INACTIVE,
  SORTING_ITEM_NAME,
  SORTING_ITEM_UPDATED,
  SORTING_ITEM_STARS,
  OVERVIEW_TABS_FILTERED_SEARCH_TERM_KEY,
} from '~/groups/constants';
import axios from '~/lib/utils/axios_utils';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import waitForPromises from 'helpers/wait_for_promises';

Vue.component('GroupFolder', GroupFolderComponent);
const router = createRouter();

describe('OverviewTabs', () => {
  let wrapper;
  let axiosMock;

  const defaultProvide = {
    groupId: '1',
    endpoints: {
      subgroups_and_projects: '/groups/foobar/-/children.json',
      shared: '/groups/foobar/-/shared_projects.json',
      archived: '/groups/foobar/-/children.json?archived=only',
    },
    newSubgroupPath: '/groups/new',
    newProjectPath: 'projects/new',
    emptyProjectsIllustration: '',
    emptySubgroupIllustration: '',
    canCreateSubgroups: false,
    canCreateProjects: false,
    initialSort: 'name_asc',
  };

  const routerMock = {
    push: jest.fn(),
  };

  const createComponent = async ({
    route = {
      name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
      params: { group: 'foo/bar/baz' },
      query: {},
    },
    provide = {},
  } = {}) => {
    wrapper = mountExtended(OverviewTabs, {
      router,
      provide: {
        ...defaultProvide,
        ...provide,
      },
      mocks: { $route: route, $router: routerMock },
    });

    await nextTick();
  };

  const findTabPanels = () => wrapper.findAllComponents(GlTab);
  const findTab = (name) => wrapper.findByRole('tab', { name });
  const findSelectedTab = () => wrapper.findByRole('tab', { selected: true });
  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);

  const emitFilter = (searchTerm) =>
    findFilteredSearchAndSort().vm.$emit('filter', {
      [OVERVIEW_TABS_FILTERED_SEARCH_TERM_KEY]: searchTerm,
    });

  const emitSortByChange = (sort) => findFilteredSearchAndSort().vm.$emit('sort-by-change', sort);
  const emitSortDirectionChange = (isAscending) =>
    findFilteredSearchAndSort().vm.$emit('sort-direction-change', isAscending);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet({ data: [] });
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('renders `Subgroups and projects` tab with `GroupsApp` component with correct empty state', async () => {
    await createComponent();

    const tabPanel = findTabPanels().at(0);

    expect(tabPanel.vm.$attrs).toMatchObject({
      title: OverviewTabs.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
      lazy: false,
    });
    expect(tabPanel.findComponent(GroupsApp).props()).toMatchObject({
      action: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
      store: new GroupsStore({ showSchemaMarkup: true }),
      service: new GroupsService(
        defaultProvide.endpoints[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
        defaultProvide.initialSort,
      ),
    });

    await waitForPromises();

    expect(wrapper.findComponent(SubgroupsAndProjectsEmptyState).exists()).toBe(true);
  });

  it('renders `Shared projects` tab and renders `GroupsApp` component with correct empty state after clicking tab', async () => {
    await createComponent();

    const tabPanel = findTabPanels().at(1);

    expect(tabPanel.vm.$attrs).toMatchObject({
      title: OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      lazy: true,
    });

    await findTab(OverviewTabs.i18n[ACTIVE_TAB_SHARED]).trigger('click');

    expect(tabPanel.findComponent(GroupsApp).props()).toMatchObject({
      action: ACTIVE_TAB_SHARED,
      store: new GroupsStore(),
      service: new GroupsService(
        defaultProvide.endpoints[ACTIVE_TAB_SHARED],
        defaultProvide.initialSort,
      ),
    });

    expect(tabPanel.vm.$attrs.lazy).toBe(false);

    await waitForPromises();

    expect(wrapper.findComponent(SharedProjectsEmptyState).exists()).toBe(true);
  });

  it('renders `Inactive projects` tab and renders `GroupsApp` component with correct empty state after clicking tab', async () => {
    await createComponent();

    const tabPanel = findTabPanels().at(2);

    expect(tabPanel.vm.$attrs).toMatchObject({
      title: OverviewTabs.i18n[ACTIVE_TAB_INACTIVE],
      lazy: true,
    });

    await findTab(OverviewTabs.i18n[ACTIVE_TAB_INACTIVE]).trigger('click');

    expect(tabPanel.findComponent(GroupsApp).props()).toMatchObject({
      action: ACTIVE_TAB_INACTIVE,
      store: new GroupsStore(),
      service: new InactiveProjectsService(defaultProvide.groupId, defaultProvide.initialSort),
    });

    expect(tabPanel.vm.$attrs.lazy).toBe(false);

    await waitForPromises();

    expect(wrapper.findComponent(InactiveProjectsEmptyState).exists()).toBe(true);
  });

  it('sets `lazy` prop to `false` for initially active tab and `true` for all other tabs', async () => {
    await createComponent({
      route: { name: ACTIVE_TAB_SHARED, params: { group: 'foo/bar' }, query: {} },
    });

    expect(findTabPanels().at(0).vm.$attrs.lazy).toBe(true);
    expect(findTabPanels().at(1).vm.$attrs.lazy).toBe(false);
    expect(findTabPanels().at(2).vm.$attrs.lazy).toBe(true);
  });

  describe.each([
    [
      { name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS, params: { group: 'foo/bar/baz' }, query: {} },
      OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      {
        name: ACTIVE_TAB_SHARED,
        params: { group: ['foo', 'bar', 'baz'] },
        query: {},
      },
    ],
    [
      {
        name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
        params: { group: ['foo', 'bar', 'baz'] },
        query: {},
      },
      OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      {
        name: ACTIVE_TAB_SHARED,
        params: { group: ['foo', 'bar', 'baz'] },
        query: {},
      },
    ],
    [
      { name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS, params: { group: 'foo' }, query: {} },
      OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      {
        name: ACTIVE_TAB_SHARED,
        params: { group: ['foo'] },
        query: {},
      },
    ],
    [
      { name: ACTIVE_TAB_SHARED, params: { group: 'foo/bar' }, query: {} },
      OverviewTabs.i18n[ACTIVE_TAB_INACTIVE],
      {
        name: ACTIVE_TAB_INACTIVE,
        params: { group: ['foo', 'bar'] },
        query: {},
      },
    ],
    [
      { name: ACTIVE_TAB_SHARED, params: { group: 'foo/bar' }, query: {} },
      OverviewTabs.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
      {
        name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
        params: { group: ['foo', 'bar'] },
        query: {},
      },
    ],
    [
      { name: ACTIVE_TAB_INACTIVE, params: { group: ['foo'] }, query: {} },
      OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      {
        name: ACTIVE_TAB_SHARED,
        params: { group: ['foo'] },
        query: {},
      },
    ],
  ])('when current route is %j', (currentRoute, tabToClick, expectedRoute) => {
    beforeEach(async () => {
      await createComponent({ route: currentRoute });
    });

    it(`sets ${OverviewTabs.i18n[currentRoute.name]} as active tab`, () => {
      expect(findSelectedTab().text()).toBe(OverviewTabs.i18n[currentRoute.name]);
    });

    it(`pushes expected route when ${tabToClick} tab is clicked`, async () => {
      await findTab(tabToClick).trigger('click');

      expect(routerMock.push).toHaveBeenCalledWith(expect.objectContaining(expectedRoute));
    });
  });

  describe('searching and sorting', () => {
    const setup = async ({ route } = {}) => {
      jest.spyOn(eventHub, '$emit');
      await createComponent({ route });

      // Click through tabs so they are all loaded
      await findTab(OverviewTabs.i18n[ACTIVE_TAB_SHARED]).trigger('click');
      await findTab(OverviewTabs.i18n[ACTIVE_TAB_INACTIVE]).trigger('click');
      await findTab(OverviewTabs.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]).trigger('click');
    };

    const sharedAssertions = ({ searchTerm, sort }) => {
      it('sets `lazy` prop to `true` for all of the non-active tabs so they are reloaded after sort or search is applied', () => {
        expect(findTabPanels().at(0).vm.$attrs.lazy).toBe(false);
        expect(findTabPanels().at(1).vm.$attrs.lazy).toBe(true);
        expect(findTabPanels().at(2).vm.$attrs.lazy).toBe(true);
      });

      it('emits `fetchFilteredAndSortedGroups` event from `eventHub`', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith(
          `${ACTIVE_TAB_SUBGROUPS_AND_PROJECTS}fetchFilteredAndSortedGroups`,
          {
            filterGroupsBy: searchTerm,
            sortBy: sort,
          },
        );
      });
    };

    describe('when search is typed in', () => {
      describe('when search is greater than or equal to 3 characters', () => {
        const searchTerm = 'Foo bar';

        beforeEach(async () => {
          await setup();

          emitFilter(searchTerm);
        });

        it('updates query string with `filter` key', () => {
          expect(routerMock.push).toHaveBeenCalledWith({ query: { filter: searchTerm } });
        });

        sharedAssertions({ searchTerm, sort: defaultProvide.initialSort });
      });

      describe('when search is less than 3 characters', () => {
        const searchTerm = 'Fo';

        beforeEach(async () => {
          await setup();
          emitFilter(searchTerm);
        });

        it('does not emit `fetchFilteredAndSortedGroups` event from `eventHub`', () => {
          expect(eventHub.$emit).not.toHaveBeenCalledWith(
            `${ACTIVE_TAB_SUBGROUPS_AND_PROJECTS}fetchFilteredAndSortedGroups`,
            {
              filterGroupsBy: searchTerm,
              sortBy: defaultProvide.initialSort,
            },
          );
        });
      });

      describe('when search is the same', () => {
        const searchTerm = 'Foo';

        beforeEach(async () => {
          await setup({
            route: {
              name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
              params: { group: 'foo/bar/baz' },
              query: { [OVERVIEW_TABS_FILTERED_SEARCH_TERM_KEY]: searchTerm },
            },
          });
          emitFilter(searchTerm);
        });

        it('does not call router.push', () => {
          expect(routerMock.push).not.toHaveBeenCalledWith({
            query: { [OVERVIEW_TABS_FILTERED_SEARCH_TERM_KEY]: searchTerm },
          });
        });
      });
    });

    describe('when sort is changed', () => {
      beforeEach(async () => {
        await setup();
        emitSortByChange(SORTING_ITEM_UPDATED.asc);
        await nextTick();
      });

      it('updates query string with `sort` key', () => {
        expect(routerMock.push).toHaveBeenCalledWith({
          query: { sort: SORTING_ITEM_UPDATED.asc },
        });
      });

      sharedAssertions({ searchTerm: '', sort: SORTING_ITEM_UPDATED.asc });
    });

    describe('when tab is changed', () => {
      describe('when selected sort is supported', () => {
        beforeEach(async () => {
          await createComponent({
            route: {
              name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
              params: { group: 'foo/bar/baz' },
              query: { sort: SORTING_ITEM_NAME.asc },
            },
          });
        });

        it('adds sort query string', async () => {
          await findTab(OverviewTabs.i18n[ACTIVE_TAB_INACTIVE]).trigger('click');

          expect(routerMock.push).toHaveBeenCalledWith(
            expect.objectContaining({
              query: { sort: SORTING_ITEM_NAME.asc },
            }),
          );
        });
      });

      describe('when selected sort is not supported', () => {
        beforeEach(async () => {
          await createComponent({
            route: {
              name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
              params: { group: 'foo/bar/baz' },
              query: { sort: SORTING_ITEM_STARS.asc },
            },
          });
        });

        it('defaults to sorting by name', async () => {
          await findTab(OverviewTabs.i18n[ACTIVE_TAB_INACTIVE]).trigger('click');

          expect(routerMock.push).toHaveBeenCalledWith(
            expect.objectContaining({
              query: { sort: SORTING_ITEM_NAME.asc },
            }),
          );
        });
      });
    });

    describe('when sort direction is changed', () => {
      beforeEach(async () => {
        await setup();
        emitSortDirectionChange(false);
      });

      it('updates query string with `sort` key', () => {
        expect(routerMock.push).toHaveBeenCalledWith({
          query: { sort: SORTING_ITEM_NAME.desc },
        });
      });

      sharedAssertions({ searchTerm: '', sort: SORTING_ITEM_NAME.desc });
    });

    describe('when `filter` and `sort` query strings are set', () => {
      const route = {
        name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
        params: { group: 'foo/bar/baz' },
        query: { filter: 'Foo bar', sort: SORTING_ITEM_UPDATED.desc },
      };

      beforeEach(async () => {
        await createComponent({
          route,
        });
      });

      it('sets correct props on `FilteredSearchAndSort` component', () => {
        expect(findFilteredSearchAndSort().props()).toMatchObject({
          filteredSearchQuery: route.query,
          activeSortOption: {
            value: SORTING_ITEM_UPDATED.desc,
            text: SORTING_ITEM_UPDATED.label,
          },
        });
      });

      describe('when search is cleared', () => {
        it('removes `filter` key from query string', () => {
          emitFilter('');

          expect(routerMock.push).toHaveBeenCalledWith({
            query: { sort: SORTING_ITEM_UPDATED.desc },
          });
        });
      });
    });
  });
});
