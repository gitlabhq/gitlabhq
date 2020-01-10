import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import createState from '~/create_cluster/gke_cluster/store/state';
import { selectedProjectMock, gapiProjectsResponseMock } from '../mock_data';
import GkeProjectIdDropdown from '~/create_cluster/gke_cluster/components/gke_project_id_dropdown.vue';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';

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

const localVue = createLocalVue();

localVue.use(Vuex);

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
      localVue,
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

    it('returns default toggle text', () => {
      bootstrap();

      wrapper.setData({ isLoading: false });

      return wrapper.vm.$nextTick().then(() => {
        expect(dropdownButtonLabel()).toBe(LABELS.DEFAULT);
      });
    });

    it('returns project name if project selected', () => {
      bootstrap(
        {
          selectedProject: selectedProjectMock,
        },
        {
          hasProject: () => true,
        },
      );
      wrapper.setData({ isLoading: false });

      return wrapper.vm.$nextTick().then(() => {
        expect(dropdownButtonLabel()).toBe(selectedProjectMock.name);
      });
    });

    it('returns empty toggle text', () => {
      bootstrap({
        projects: null,
      });
      wrapper.setData({ isLoading: false });

      return wrapper.vm.$nextTick().then(() => {
        expect(dropdownButtonLabel()).toBe(LABELS.EMPTY);
      });
    });
  });

  describe('selectItem', () => {
    it('reflects new value when dropdown item is clicked', () => {
      bootstrap({ projects: gapiProjectsResponseMock.projects });

      expect(dropdownHiddenInputValue()).toBe('');

      wrapper.find('.dropdown-content button').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(setProject).toHaveBeenCalledWith(
          expect.anything(),
          gapiProjectsResponseMock.projects[0],
          undefined,
        );
      });
    });
  });
});
