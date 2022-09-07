import { GlTab } from '@gitlab/ui';
import { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import OverviewTabs from '~/groups/components/overview_tabs.vue';
import GroupsApp from '~/groups/components/app.vue';
import GroupsStore from '~/groups/store/groups_store';
import GroupsService from '~/groups/service/groups_service';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_ARCHIVED,
} from '~/groups/constants';
import axios from '~/lib/utils/axios_utils';

describe('OverviewTabs', () => {
  let wrapper;

  const endpoints = {
    subgroups_and_projects: '/groups/foobar/-/children.json',
    shared: '/groups/foobar/-/shared_projects.json',
    archived: '/groups/foobar/-/children.json?archived=only',
  };

  const createComponent = async () => {
    wrapper = mountExtended(OverviewTabs, {
      provide: {
        endpoints,
      },
    });

    await nextTick();
  };

  const findTabPanels = () => wrapper.findAllComponents(GlTab);
  const findTab = (name) => wrapper.findByRole('tab', { name });

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(async () => {
    // eslint-disable-next-line no-new
    new AxiosMockAdapter(axios);

    await createComponent();
  });

  it('renders `Subgroups and projects` tab with `GroupsApp` component', async () => {
    const tabPanel = findTabPanels().at(0);

    expect(tabPanel.vm.$attrs).toMatchObject({
      title: OverviewTabs.i18n.subgroupsAndProjects,
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
    const tabPanel = findTabPanels().at(1);

    expect(tabPanel.vm.$attrs).toMatchObject({
      title: OverviewTabs.i18n.sharedProjects,
      lazy: true,
    });

    await findTab(OverviewTabs.i18n.sharedProjects).trigger('click');

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
    const tabPanel = findTabPanels().at(2);

    expect(tabPanel.vm.$attrs).toMatchObject({
      title: OverviewTabs.i18n.archivedProjects,
      lazy: true,
    });

    await findTab(OverviewTabs.i18n.archivedProjects).trigger('click');

    expect(tabPanel.findComponent(GroupsApp).props()).toMatchObject({
      action: ACTIVE_TAB_ARCHIVED,
      store: new GroupsStore(),
      service: new GroupsService(endpoints[ACTIVE_TAB_ARCHIVED]),
      hideProjects: false,
      renderEmptyState: false,
    });

    expect(tabPanel.vm.$attrs.lazy).toBe(false);
  });
});
