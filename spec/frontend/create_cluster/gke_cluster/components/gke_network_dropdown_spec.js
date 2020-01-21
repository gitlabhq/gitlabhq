import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import GkeNetworkDropdown from '~/create_cluster/gke_cluster/components/gke_network_dropdown.vue';
import ClusterFormDropdown from '~/create_cluster/components/cluster_form_dropdown.vue';
import createClusterDropdownState from '~/create_cluster/store/cluster_dropdown/state';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('GkeNetworkDropdown', () => {
  let wrapper;
  let store;
  const defaultProps = { fieldName: 'field-name' };
  const selectedNetwork = { selfLink: '123456' };
  const projectId = '6789';
  const region = 'east-1';
  const setNetwork = jest.fn();
  const setSubnetwork = jest.fn();
  const fetchSubnetworks = jest.fn();

  const buildStore = ({ clusterDropdownState } = {}) =>
    new Vuex.Store({
      state: {
        selectedNetwork,
      },
      actions: {
        setNetwork,
        setSubnetwork,
      },
      getters: {
        hasZone: () => false,
        region: () => region,
        projectId: () => projectId,
      },
      modules: {
        networks: {
          namespaced: true,
          state: {
            ...createClusterDropdownState(),
            ...(clusterDropdownState || {}),
          },
        },
        subnetworks: {
          namespaced: true,
          actions: {
            fetchItems: fetchSubnetworks,
          },
        },
      },
    });

  const buildWrapper = (propsData = defaultProps) =>
    shallowMount(GkeNetworkDropdown, {
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

  it('sets selected network as the dropdown value', () => {
    store = buildStore();
    wrapper = buildWrapper();

    expect(wrapper.find(ClusterFormDropdown).props('value')).toBe(selectedNetwork);
  });

  it('maps networks store items to the dropdown items property', () => {
    const items = [{ name: 'network' }];

    store = buildStore({ clusterDropdownState: { items } });
    wrapper = buildWrapper();

    expect(wrapper.find(ClusterFormDropdown).props('items')).toBe(items);
  });

  describe('when network dropdown store is loading items', () => {
    it('sets network dropdown as loading', () => {
      store = buildStore({ clusterDropdownState: { isLoadingItems: true } });
      wrapper = buildWrapper();

      expect(wrapper.find(ClusterFormDropdown).props('loading')).toBe(true);
    });
  });

  describe('when there is no selected zone', () => {
    it('disables the network dropdown', () => {
      store = buildStore();
      wrapper = buildWrapper();

      expect(wrapper.find(ClusterFormDropdown).props('disabled')).toBe(true);
    });
  });

  describe('when an error occurs while loading networks', () => {
    it('sets the network dropdown as having errors', () => {
      store = buildStore({ clusterDropdownState: { loadingItemsError: new Error() } });
      wrapper = buildWrapper();

      expect(wrapper.find(ClusterFormDropdown).props('hasErrors')).toBe(true);
    });
  });

  describe('when dropdown emits input event', () => {
    beforeEach(() => {
      store = buildStore();
      wrapper = buildWrapper();
      wrapper.find(ClusterFormDropdown).vm.$emit('input', selectedNetwork);
    });

    it('cleans selected subnetwork', () => {
      expect(setSubnetwork).toHaveBeenCalledWith(expect.anything(), '', undefined);
    });

    it('dispatches the setNetwork action', () => {
      expect(setNetwork).toHaveBeenCalledWith(expect.anything(), selectedNetwork, undefined);
    });

    it('fetches subnetworks for the selected project, region, and network', () => {
      expect(fetchSubnetworks).toHaveBeenCalledWith(
        expect.anything(),
        {
          project: projectId,
          region,
          network: selectedNetwork.selfLink,
        },
        undefined,
      );
    });
  });
});
