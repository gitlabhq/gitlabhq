import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Vue from 'vue';
import EksClusterConfigurationForm from '~/create_cluster/eks_cluster/components/eks_cluster_configuration_form.vue';
import RegionDropdown from '~/create_cluster/eks_cluster/components/region_dropdown.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EksClusterConfigurationForm', () => {
  let store;
  let actions;
  let state;
  let vm;

  beforeEach(() => {
    actions = {
      fetchRegions: jest.fn(),
      setRegion: jest.fn(),
    };
    state = {
      regions: [{ name: 'region 1' }],
      isLoadingRegions: false,
      loadingRegionsError: { message: '' },
    };
    store = new Vuex.Store({
      state,
      actions,
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
      expect(actions.fetchRegions).toHaveBeenCalled();
    });
  });

  it('sets isLoadingRegions to RegionDropdown loading property', () => {
    state.isLoadingRegions = true;

    return Vue.nextTick().then(() => {
      expect(findRegionDropdown().props('loading')).toEqual(state.isLoadingRegions);
    });
  });

  it('sets regions to RegionDropdown regions property', () => {
    expect(findRegionDropdown().props('regions')).toEqual(state.regions);
  });

  it('sets loadingRegionsError to RegionDropdown error property', () => {
    expect(findRegionDropdown().props('error')).toEqual(state.loadingRegionsError);
  });

  it('dispatches setRegion action when region is selected', () => {
    const region = { region: 'us-west-2' };

    findRegionDropdown().vm.$emit('input', region);

    expect(actions.setRegion).toHaveBeenCalledWith(expect.anything(), { region }, undefined);
  });
});
