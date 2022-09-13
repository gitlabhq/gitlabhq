import { GlTab } from '@gitlab/ui';
import { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import OverviewTabs from '~/groups/components/overview_tabs.vue';
import GroupsApp from '~/groups/components/app.vue';
import GroupsStore from '~/groups/store/groups_store';
import GroupsService from '~/groups/service/groups_service';
import { createRouter } from '~/groups/init_overview_tabs';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_ARCHIVED,
} from '~/groups/constants';
import axios from '~/lib/utils/axios_utils';

const router = createRouter();

describe('OverviewTabs', () => {
  let wrapper;

  const endpoints = {
    subgroups_and_projects: '/groups/foobar/-/children.json',
    shared: '/groups/foobar/-/shared_projects.json',
    archived: '/groups/foobar/-/children.json?archived=only',
  };

  const routerMock = {
    push: jest.fn(),
  };

  const createComponent = async ({
    route = { name: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS, params: { group: 'foo/bar/baz' } },
  } = {}) => {
    wrapper = mountExtended(OverviewTabs, {
      router,
      provide: {
        endpoints,
      },
      mocks: { $route: route, $router: routerMock },
    });

    await nextTick();
  };

  const findTabPanels = () => wrapper.findAllComponents(GlTab);
  const findTab = (name) => wrapper.findByRole('tab', { name });
  const findSelectedTab = () => wrapper.findByRole('tab', { selected: true });

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(async () => {
    // eslint-disable-next-line no-new
    new AxiosMockAdapter(axios);
  });

  it('renders `Subgroups and projects` tab with `GroupsApp` component', async () => {
    await createComponent();

    const tabPanel = findTabPanels().at(0);

    expect(tabPanel.vm.$attrs).toMatchObject({
      title: OverviewTabs.i18n[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS],
      lazy: false,
    });
    expect(tabPanel.findComponent(GroupsApp).props()).toMatchObject({
      action: ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
      store: new GroupsStore({ showSchemaMarkup: true }),
      service: new GroupsService(endpoints[ACTIVE_TAB_SUBGROUPS_AND_PROJECTS]),
      hideProjects: false,
      renderEmptyState: true,
    });
  });

  it('renders `Shared projects` tab and renders `GroupsApp` component after clicking tab', async () => {
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
      service: new GroupsService(endpoints[ACTIVE_TAB_SHARED]),
      hideProjects: false,
      renderEmptyState: false,
    });

    expect(tabPanel.vm.$attrs.lazy).toBe(false);
  });

  it('renders `Archived projects` tab and renders `GroupsApp` component after clicking tab', async () => {
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
      service: new GroupsService(endpoints[ACTIVE_TAB_ARCHIVED]),
      hideProjects: false,
      renderEmptyState: false,
    });

    expect(tabPanel.vm.$attrs.lazy).toBe(false);
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
});
