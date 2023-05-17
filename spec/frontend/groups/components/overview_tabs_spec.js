import { GlSorting, GlSortingItem, GlTab } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import OverviewTabs from '~/groups/components/overview_tabs.vue';
import GroupsApp from '~/groups/components/app.vue';
import GroupFolderComponent from '~/groups/components/group_folder.vue';
import SubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/subgroups_and_projects_empty_state.vue';
import SharedProjectsEmptyState from '~/groups/components/empty_states/shared_projects_empty_state.vue';
import ArchivedProjectsEmptyState from '~/groups/components/empty_states/archived_projects_empty_state.vue';
import GroupsStore from '~/groups/store/groups_store';
import GroupsService from '~/groups/service/groups_service';
import { createRouter } from '~/groups/init_overview_tabs';
import eventHub from '~/groups/event_hub';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_ARCHIVED,
  OVERVIEW_TABS_SORTING_ITEMS,
} from '~/groups/constants';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';

Vue.component('GroupFolder', GroupFolderComponent);
const router = createRouter();
const [SORTING_ITEM_NAME, , SORTING_ITEM_UPDATED] = OVERVIEW_TABS_SORTING_ITEMS;

describe('OverviewTabs', () => {
  let wrapper;
  let axiosMock;

  const defaultProvide = {
    endpoints: {
      subgroups_and_projects: '/groups/foobar/-/children.json',
      shared: '/groups/foobar/-/shared_projects.json',
      archived: '/groups/foobar/-/children.json?archived=only',
    },
    newSubgroupPath: '/groups/new',
    newProjectPath: 'projects/new',
    newSubgroupIllustration: '',
    newProjectIllustration: '',
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
    route = { name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS, params: { group: 'foo/bar/baz' } },
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
  const findSearchInput = () => wrapper.findByPlaceholderText(OverviewTabs.i18n.searchPlaceholder);

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
      service: new GroupsService(defaultProvide.endpoints[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]),
      hideProjects: false,
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
      service: new GroupsService(defaultProvide.endpoints[ACTIVE_TAB_SHARED]),
      hideProjects: false,
    });

    expect(tabPanel.vm.$attrs.lazy).toBe(false);

    await waitForPromises();

    expect(wrapper.findComponent(SharedProjectsEmptyState).exists()).toBe(true);
  });

  it('renders `Archived projects` tab and renders `GroupsApp` component with correct empty state after clicking tab', async () => {
    await createComponent();

    const tabPanel = findTabPanels().at(2);

    expect(tabPanel.vm.$attrs).toMatchObject({
      title: OverviewTabs.i18n[ACTIVE_TAB_ARCHIVED],
      lazy: true,
    });

    await findTab(OverviewTabs.i18n[ACTIVE_TAB_ARCHIVED]).trigger('click');

    expect(tabPanel.findComponent(GroupsApp).props()).toMatchObject({
      action: ACTIVE_TAB_ARCHIVED,
      store: new GroupsStore(),
      service: new GroupsService(defaultProvide.endpoints[ACTIVE_TAB_ARCHIVED]),
      hideProjects: false,
    });

    expect(tabPanel.vm.$attrs.lazy).toBe(false);

    await waitForPromises();

    expect(wrapper.findComponent(ArchivedProjectsEmptyState).exists()).toBe(true);
  });

  it('sets `lazy` prop to `false` for initially active tab and `true` for all other tabs', async () => {
    await createComponent({ route: { name: ACTIVE_TAB_SHARED, params: { group: 'foo/bar' } } });

    expect(findTabPanels().at(0).vm.$attrs.lazy).toBe(true);
    expect(findTabPanels().at(1).vm.$attrs.lazy).toBe(false);
    expect(findTabPanels().at(2).vm.$attrs.lazy).toBe(true);
  });

  describe.each([
    [
      { name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS, params: { group: 'foo/bar/baz' } },
      OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      {
        name: ACTIVE_TAB_SHARED,
        params: { group: ['foo', 'bar', 'baz'] },
      },
    ],
    [
      { name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS, params: { group: ['foo', 'bar', 'baz'] } },
      OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      {
        name: ACTIVE_TAB_SHARED,
        params: { group: ['foo', 'bar', 'baz'] },
      },
    ],
    [
      { name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS, params: { group: 'foo' } },
      OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      {
        name: ACTIVE_TAB_SHARED,
        params: { group: ['foo'] },
      },
    ],
    [
      { name: ACTIVE_TAB_SHARED, params: { group: 'foo/bar' } },
      OverviewTabs.i18n[ACTIVE_TAB_ARCHIVED],
      {
        name: ACTIVE_TAB_ARCHIVED,
        params: { group: ['foo', 'bar'] },
      },
    ],
    [
      { name: ACTIVE_TAB_SHARED, params: { group: 'foo/bar' } },
      OverviewTabs.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
      {
        name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
        params: { group: ['foo', 'bar'] },
      },
    ],
    [
      { name: ACTIVE_TAB_ARCHIVED, params: { group: ['foo'] } },
      OverviewTabs.i18n[ACTIVE_TAB_SHARED],
      {
        name: ACTIVE_TAB_SHARED,
        params: { group: ['foo'] },
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

      expect(routerMock.push).toHaveBeenCalledWith(expectedRoute);
    });
  });

  describe('searching and sorting', () => {
    const setup = async () => {
      jest.spyOn(eventHub, '$emit');
      await createComponent();

      // Click through tabs so they are all loaded
      await findTab(OverviewTabs.i18n[ACTIVE_TAB_SHARED]).trigger('click');
      await findTab(OverviewTabs.i18n[ACTIVE_TAB_ARCHIVED]).trigger('click');
      await findTab(OverviewTabs.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]).trigger('click');
    };

    const sharedAssertions = ({ search, sort }) => {
      it('sets `lazy` prop to `true` for all of the non-active tabs so they are reloaded after sort or search is applied', () => {
        expect(findTabPanels().at(0).vm.$attrs.lazy).toBe(false);
        expect(findTabPanels().at(1).vm.$attrs.lazy).toBe(true);
        expect(findTabPanels().at(2).vm.$attrs.lazy).toBe(true);
      });

      it('emits `fetchFilteredAndSortedGroups` event from `eventHub`', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith(
          `${ACTIVE_TAB_SUBGROUPS_AND_PROJECTS}fetchFilteredAndSortedGroups`,
          {
            filterGroupsBy: search,
            sortBy: sort,
          },
        );
      });
    };

    describe('when search is typed in', () => {
      describe('when search is greater than or equal to 3 characters', () => {
        const search = 'Foo bar';

        beforeEach(async () => {
          await setup();
          await findSearchInput().setValue(search);
        });

        it('updates query string with `filter` key', () => {
          expect(routerMock.push).toHaveBeenCalledWith({ query: { filter: search } });
        });

        sharedAssertions({ search, sort: defaultProvide.initialSort });
      });

      describe('when search is less than 3 characters', () => {
        const search = 'Fo';

        beforeEach(async () => {
          await setup();
          await findSearchInput().setValue(search);
        });

        it('does not emit `fetchFilteredAndSortedGroups` event from `eventHub`', () => {
          expect(eventHub.$emit).not.toHaveBeenCalledWith(
            `${ACTIVE_TAB_SUBGROUPS_AND_PROJECTS}fetchFilteredAndSortedGroups`,
            {
              filterGroupsBy: search,
              sortBy: defaultProvide.initialSort,
            },
          );
        });
      });
    });

    describe('when sort is changed', () => {
      beforeEach(async () => {
        await setup();
        wrapper.findAllComponents(GlSortingItem).at(2).vm.$emit('click');
        await nextTick();
      });

      it('updates query string with `sort` key', () => {
        expect(routerMock.push).toHaveBeenCalledWith({
          query: { sort: SORTING_ITEM_UPDATED.asc },
        });
      });

      sharedAssertions({ search: '', sort: SORTING_ITEM_UPDATED.asc });
    });

    describe('when sort direction is changed', () => {
      beforeEach(async () => {
        await setup();
        await wrapper
          .findByRole('button', { name: 'Sorting Direction: Ascending' })
          .trigger('click');
      });

      it('updates query string with `sort` key', () => {
        expect(routerMock.push).toHaveBeenCalledWith({
          query: { sort: SORTING_ITEM_NAME.desc },
        });
      });

      sharedAssertions({ search: '', sort: SORTING_ITEM_NAME.desc });
    });

    describe('when `filter` and `sort` query strings are set', () => {
      beforeEach(async () => {
        await createComponent({
          route: {
            name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
            params: { group: 'foo/bar/baz' },
            query: { filter: 'Foo bar', sort: SORTING_ITEM_UPDATED.desc },
          },
        });
      });

      it('sets value of search input', () => {
        expect(
          wrapper.findByPlaceholderText(OverviewTabs.i18n.searchPlaceholder).element.value,
        ).toBe('Foo bar');
      });

      describe('when search is cleared', () => {
        it('removes `filter` key from query string', async () => {
          await findSearchInput().setValue('');

          expect(routerMock.push).toHaveBeenCalledWith({
            query: { sort: SORTING_ITEM_UPDATED.desc },
          });
        });
      });

      it('sets sort dropdown', () => {
        expect(wrapper.findComponent(GlSorting).props()).toMatchObject({
          text: SORTING_ITEM_UPDATED.label,
          isAscending: false,
        });

        expect(wrapper.findAllComponents(GlSortingItem).at(2).vm.$attrs.active).toBe(true);
      });
    });
  });
});
