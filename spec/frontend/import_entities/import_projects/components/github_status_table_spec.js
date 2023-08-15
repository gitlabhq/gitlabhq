import { GlTabs, GlSearchBoxByClick } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import { stubComponent } from 'helpers/stub_component';
import GithubStatusTable from '~/import_entities/import_projects/components/github_status_table.vue';
import GithubOrganizationsBox from '~/import_entities/import_projects/components/github_organizations_box.vue';
import ImportProjectsTable from '~/import_entities/import_projects/components/import_projects_table.vue';
import initialState from '~/import_entities/import_projects/store/state';
import * as getters from '~/import_entities/import_projects/store/getters';

const ImportProjectsTableStub = stubComponent(ImportProjectsTable, {
  importAllButtonText: 'IMPORT_ALL_TEXT',
  methods: {
    showImportAllModal: jest.fn(),
  },
  template:
    '<div><slot name="filter" v-bind="{ importAllButtonText: $options.importAllButtonText, showImportAllModal }"></slot></div>',
});

Vue.use(Vuex);

describe('GithubStatusTable', () => {
  let wrapper;

  const setFilterAction = jest.fn().mockImplementation(({ state }, filter) => {
    state.filter = { ...state.filter, ...filter };
  });

  const findFilterField = () => wrapper.findComponent(GlSearchBoxByClick);
  const selectTab = (idx) => {
    wrapper.findComponent(GlTabs).vm.$emit('input', idx);
    return nextTick();
  };

  function createComponent() {
    const store = new Vuex.Store({
      state: { ...initialState() },
      getters,
      actions: {
        setFilter: setFilterAction,
      },
    });

    wrapper = mount(GithubStatusTable, {
      store,
      propsData: {
        providerTitle: 'Github',
      },
      stubs: {
        ImportProjectsTable: ImportProjectsTableStub,
        GithubOrganizationsBox: stubComponent(GithubOrganizationsBox),
        GlTabs: false,
        GlTab: false,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('renders import table component', () => {
    expect(wrapper.findComponent(ImportProjectsTable).exists()).toBe(true);
  });

  it('sets relation_type filter to owned repositories by default', () => {
    expect(setFilterAction).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ relation_type: 'owned' }),
    );
  });

  it('updates relation_type and resets organization filter when tab is switched', async () => {
    const NEW_ACTIVE_TAB_IDX = 1;
    await selectTab(NEW_ACTIVE_TAB_IDX);

    expect(setFilterAction).toHaveBeenCalledTimes(2);
    expect(setFilterAction).toHaveBeenCalledWith(expect.anything(), {
      ...GithubStatusTable.relationTypes[NEW_ACTIVE_TAB_IDX].backendFilter,
      organization_login: '',
      filter: '',
    });
  });

  it('renders name filter disabled when tab with organization filter is selected and organization is not set', async () => {
    const NEW_ACTIVE_TAB_IDX = GithubStatusTable.relationTypes.findIndex(
      (entry) => entry.showOrganizationFilter,
    );
    await selectTab(NEW_ACTIVE_TAB_IDX);
    expect(findFilterField().props('disabled')).toBe(true);
  });

  it('enables name filter disabled when organization is set', async () => {
    const NEW_ACTIVE_TAB_IDX = GithubStatusTable.relationTypes.findIndex(
      (entry) => entry.showOrganizationFilter,
    );
    await selectTab(NEW_ACTIVE_TAB_IDX);

    wrapper.findComponent(GithubOrganizationsBox).vm.$emit('input', 'some-org');
    await nextTick();

    expect(findFilterField().props('disabled')).toBe(false);
  });

  it('updates filter when search box is changed', async () => {
    const NEW_FILTER = 'test';
    findFilterField().vm.$emit('submit', NEW_FILTER);
    await nextTick();

    expect(setFilterAction).toHaveBeenCalledWith(expect.anything(), {
      filter: NEW_FILTER,
    });
  });

  it('updates organization_login filter when GithubOrganizationsBox emits input', () => {
    const NEW_ORG = 'some-org';
    wrapper.findComponent(GithubOrganizationsBox).vm.$emit('input', NEW_ORG);

    expect(setFilterAction).toHaveBeenCalledWith(expect.anything(), {
      organization_login: NEW_ORG,
    });
  });
});
