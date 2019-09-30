import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Vue from 'vue';
import EksClusterConfigurationForm from '~/create_cluster/eks_cluster/components/eks_cluster_configuration_form.vue';
import RegionDropdown from '~/create_cluster/eks_cluster/components/region_dropdown.vue';

import clusterDropdownStoreState from '~/create_cluster/eks_cluster/store/cluster_dropdown/state';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EksClusterConfigurationForm', () => {
  let store;
  let actions;
  let regionsState;
  let regionsActions;
  let vm;

  beforeEach(() => {
    actions = {
      setRegion: jest.fn(),
      setVpc: jest.fn(),
    };
    regionsActions = {
      fetchItems: jest.fn(),
    };
    regionsState = {
      ...clusterDropdownStoreState(),
    };
    store = new Vuex.Store({
      actions,
      modules: {
        regions: {
          namespaced: true,
          state: regionsState,
          actions: regionsActions,
        },
      },
    });
  });

  beforeEach(() => {
    vm = shallowMount(EksClusterConfigurationForm, {
      localVue,
      store,
    });
  });

  afterEach(() => {
    vm.destroy();
  });

  const findRegionDropdown = () => vm.find(RegionDropdown);

  describe('when mounted', () => {
    it('fetches available regions', () => {
      expect(regionsActions.fetchItems).toHaveBeenCalled();
    });
  });

  it('sets isLoadingRegions to RegionDropdown loading property', () => {
    regionsState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findRegionDropdown().props('loading')).toEqual(regionsState.isLoadingItems);
    });
  });

  it('sets regions to RegionDropdown regions property', () => {
    expect(findRegionDropdown().props('regions')).toEqual(regionsState.items);
  });

  it('sets loadingRegionsError to RegionDropdown error property', () => {
    expect(findRegionDropdown().props('error')).toEqual(regionsState.loadingItemsError);
  });

  describe('when region is selected', () => {
    const region = { name: 'us-west-2' };

    beforeEach(() => {
      findRegionDropdown().vm.$emit('input', region);
    });

    it('dispatches setRegion action', () => {
      expect(actions.setRegion).toHaveBeenCalledWith(expect.anything(), { region }, undefined);
    });
  });
});
