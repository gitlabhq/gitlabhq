import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { selectedMachineTypeMock, gapiMachineTypesResponseMock } from '../mock_data';
import createState from '~/create_cluster/gke_cluster/store/state';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';
import GkeMachineTypeDropdown from '~/create_cluster/gke_cluster/components/gke_machine_type_dropdown.vue';

const componentConfig = {
  fieldId: 'cluster_provider_gcp_attributes_gcp_machine_type',
  fieldName: 'cluster[provider_gcp_attributes][gcp_machine_type]',
};
const setMachineType = jest.fn();

const LABELS = {
  LOADING: 'Fetching machine types',
  DISABLED_NO_PROJECT: 'Select project and zone to choose machine type',
  DISABLED_NO_ZONE: 'Select zone to choose machine type',
  DEFAULT: 'Select machine type',
};

const localVue = createLocalVue();

localVue.use(Vuex);

const createComponent = (store, propsData = componentConfig) =>
  shallowMount(GkeMachineTypeDropdown, {
    propsData,
    store,
    localVue,
  });

const createStore = (initialState = {}, getters = {}) =>
  new Vuex.Store({
    state: {
      ...createState(),
      ...initialState,
    },
    getters: {
      hasZone: () => false,
      ...getters,
    },
    actions: {
      setMachineType,
    },
  });

describe('GkeMachineTypeDropdown', () => {
  let wrapper;
  let store;

  afterEach(() => {
    wrapper.destroy();
  });

  const dropdownButtonLabel = () => wrapper.find(DropdownButton).props('toggleText');
  const dropdownHiddenInputValue = () => wrapper.find(DropdownHiddenInput).props('value');

  describe('shows various toggle text depending on state', () => {
    it('returns disabled state toggle text when no project and zone are selected', () => {
      store = createStore({
        projectHasBillingEnabled: false,
      });
      wrapper = createComponent(store);

      expect(dropdownButtonLabel()).toBe(LABELS.DISABLED_NO_PROJECT);
    });

    it('returns disabled state toggle text when no zone is selected', () => {
      store = createStore({
        projectHasBillingEnabled: true,
      });
      wrapper = createComponent(store);

      expect(dropdownButtonLabel()).toBe(LABELS.DISABLED_NO_ZONE);
    });

    it('returns loading toggle text', () => {
      store = createStore();
      wrapper = createComponent(store);

      wrapper.setData({ isLoading: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(dropdownButtonLabel()).toBe(LABELS.LOADING);
      });
    });

    it('returns default toggle text', () => {
      store = createStore(
        {
          projectHasBillingEnabled: true,
        },
        { hasZone: () => true },
      );
      wrapper = createComponent(store);

      expect(dropdownButtonLabel()).toBe(LABELS.DEFAULT);
    });

    it('returns machine type name if machine type selected', () => {
      store = createStore(
        {
          projectHasBillingEnabled: true,
          selectedMachineType: selectedMachineTypeMock,
        },
        { hasZone: () => true },
      );
      wrapper = createComponent(store);

      expect(dropdownButtonLabel()).toBe(selectedMachineTypeMock);
    });
  });

  describe('form input', () => {
    it('reflects new value when dropdown item is clicked', () => {
      store = createStore({
        machineTypes: gapiMachineTypesResponseMock.items,
      });
      wrapper = createComponent(store);

      expect(dropdownHiddenInputValue()).toBe('');

      wrapper.find('.dropdown-content button').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(setMachineType).toHaveBeenCalledWith(
          expect.anything(),
          selectedMachineTypeMock,
          undefined,
        );
      });
    });
  });
});
