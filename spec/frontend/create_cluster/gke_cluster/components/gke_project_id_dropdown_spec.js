import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import GkeProjectIdDropdown from '~/create_cluster/gke_cluster/components/gke_project_id_dropdown.vue';
import createState from '~/create_cluster/gke_cluster/store/state';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';
import { selectedProjectMock, gapiProjectsResponseMock } from '../mock_data';

const componentConfig = {
  docsUrl: 'https://console.cloud.google.com/home/dashboard',
  fieldId: 'cluster_provider_gcp_attributes_gcp_project_id',
  fieldName: 'cluster[provider_gcp_attributes][gcp_project_id]',
};

const LABELS = {
  LOADING: 'Fetching projects',
  VALIDATING_PROJECT_BILLING: 'Validating project billing status',
  DEFAULT: 'Select project',
  EMPTY: 'No projects found',
};

Vue.use(Vuex);

describe('GkeProjectIdDropdown', () => {
  let wrapper;
  let vuexStore;
  let setProject;

  beforeEach(() => {
    setProject = jest.fn();
  });

  const createStore = (initialState = {}, getters = {}) =>
    new Vuex.Store({
      state: {
        ...createState(),
        ...initialState,
      },
      actions: {
        fetchProjects: jest.fn().mockResolvedValueOnce([]),
        setProject,
      },
      getters: {
        hasProject: () => false,
        ...getters,
      },
    });

  const createComponent = (store, propsData = componentConfig) =>
    shallowMount(GkeProjectIdDropdown, {
      propsData,
      store,
    });

  const bootstrap = (initialState, getters) => {
    vuexStore = createStore(initialState, getters);
    wrapper = createComponent(vuexStore);
  };

  const dropdownButtonLabel = () => wrapper.find(DropdownButton).props('toggleText');
  const dropdownHiddenInputValue = () => wrapper.find(DropdownHiddenInput).props('value');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('toggleText', () => {
    it('returns loading toggle text', () => {
      bootstrap();

      expect(dropdownButtonLabel()).toBe(LABELS.LOADING);
    });

    it('returns project billing validation text', () => {
      bootstrap({ isValidatingProjectBilling: true });

      expect(dropdownButtonLabel()).toBe(LABELS.VALIDATING_PROJECT_BILLING);
    });

    it('returns default toggle text', async () => {
      bootstrap();

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ isLoading: false });

      await nextTick();
      expect(dropdownButtonLabel()).toBe(LABELS.DEFAULT);
    });

    it('returns project name if project selected', async () => {
      bootstrap(
        {
          selectedProject: selectedProjectMock,
        },
        {
          hasProject: () => true,
        },
      );
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ isLoading: false });

      await nextTick();
      expect(dropdownButtonLabel()).toBe(selectedProjectMock.name);
    });

    it('returns empty toggle text', async () => {
      bootstrap({
        projects: null,
      });
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ isLoading: false });

      await nextTick();
      expect(dropdownButtonLabel()).toBe(LABELS.EMPTY);
    });
  });

  describe('selectItem', () => {
    it('reflects new value when dropdown item is clicked', async () => {
      bootstrap({ projects: gapiProjectsResponseMock.projects });

      expect(dropdownHiddenInputValue()).toBe('');

      wrapper.find('.dropdown-content button').trigger('click');

      await nextTick();
      expect(setProject).toHaveBeenCalledWith(
        expect.anything(),
        gapiProjectsResponseMock.projects[0],
      );
    });
  });
});
