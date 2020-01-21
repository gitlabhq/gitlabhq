import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import GkeSubnetworkDropdown from '~/create_cluster/gke_cluster/components/gke_subnetwork_dropdown.vue';
import ClusterFormDropdown from '~/create_cluster/components/cluster_form_dropdown.vue';
import createClusterDropdownState from '~/create_cluster/store/cluster_dropdown/state';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('GkeSubnetworkDropdown', () => {
  let wrapper;
  let store;
  const defaultProps = { fieldName: 'field-name' };
  const selectedSubnetwork = '123456';
  const setSubnetwork = jest.fn();

  const buildStore = ({ clusterDropdownState } = {}) =>
    new Vuex.Store({
      state: {
        selectedSubnetwork,
      },
      actions: {
        setSubnetwork,
      },
      getters: {
        hasNetwork: () => false,
      },
      modules: {
        subnetworks: {
          namespaced: true,
          state: {
            ...createClusterDropdownState(),
            ...(clusterDropdownState || {}),
          },
        },
      },
    });

  const buildWrapper = (propsData = defaultProps) =>
    shallowMount(GkeSubnetworkDropdown, {
      propsData,
      store,
      localVue,
    });

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets correct field-name', () => {
    const fieldName = 'field-name';

    store = buildStore();
    wrapper = buildWrapper({ fieldName });

    expect(wrapper.find(ClusterFormDropdown).props('fieldName')).toBe(fieldName);
  });

  it('sets selected subnetwork as the dropdown value', () => {
    store = buildStore();
    wrapper = buildWrapper();

    expect(wrapper.find(ClusterFormDropdown).props('value')).toBe(selectedSubnetwork);
  });

  it('maps subnetworks store items to the dropdown items property', () => {
    const items = [{ name: 'subnetwork' }];

    store = buildStore({ clusterDropdownState: { items } });
    wrapper = buildWrapper();

    expect(wrapper.find(ClusterFormDropdown).props('items')).toBe(items);
  });

  describe('when subnetwork dropdown store is loading items', () => {
    it('sets subnetwork dropdown as loading', () => {
      store = buildStore({ clusterDropdownState: { isLoadingItems: true } });
      wrapper = buildWrapper();

      expect(wrapper.find(ClusterFormDropdown).props('loading')).toBe(true);
    });
  });

  describe('when there is no selected network', () => {
    it('disables the subnetwork dropdown', () => {
      store = buildStore();
      wrapper = buildWrapper();

      expect(wrapper.find(ClusterFormDropdown).props('disabled')).toBe(true);
    });
  });

  describe('when an error occurs while loading subnetworks', () => {
    it('sets the subnetwork dropdown as having errors', () => {
      store = buildStore({ clusterDropdownState: { loadingItemsError: new Error() } });
      wrapper = buildWrapper();

      expect(wrapper.find(ClusterFormDropdown).props('hasErrors')).toBe(true);
    });
  });

  describe('when dropdown emits input event', () => {
    it('dispatches the setSubnetwork action', () => {
      store = buildStore();
      wrapper = buildWrapper();

      wrapper.find(ClusterFormDropdown).vm.$emit('input', selectedSubnetwork);

      expect(setSubnetwork).toHaveBeenCalledWith(expect.anything(), selectedSubnetwork, undefined);
    });
  });
});
