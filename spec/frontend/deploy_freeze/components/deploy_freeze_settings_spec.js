import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import DeployFreezeSettings from '~/deploy_freeze/components/deploy_freeze_settings.vue';
import DeployFreezeTable from '~/deploy_freeze/components/deploy_freeze_table.vue';
import DeployFreezeModal from '~/deploy_freeze/components/deploy_freeze_modal.vue';
import createStore from '~/deploy_freeze/store';
import { timezoneDataFixture } from '../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Deploy freeze settings', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore({
      projectId: '8',
      timezoneData: timezoneDataFixture,
    });
    jest.spyOn(store, 'dispatch').mockImplementation();
    wrapper = shallowMount(DeployFreezeSettings, {
      localVue,
      store,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Deploy freeze table contains components', () => {
    it('contains deploy freeze table', () => {
      expect(wrapper.find(DeployFreezeTable).exists()).toBe(true);
    });

    it('contains deploy freeze modal', () => {
      expect(wrapper.find(DeployFreezeModal).exists()).toBe(true);
    });
  });
});
