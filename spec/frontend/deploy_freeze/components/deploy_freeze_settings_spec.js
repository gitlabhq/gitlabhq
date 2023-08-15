import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import DeployFreezeModal from '~/deploy_freeze/components/deploy_freeze_modal.vue';
import DeployFreezeSettings from '~/deploy_freeze/components/deploy_freeze_settings.vue';
import DeployFreezeTable from '~/deploy_freeze/components/deploy_freeze_table.vue';
import createStore from '~/deploy_freeze/store';
import { timezoneDataFixture } from '../../vue_shared/components/timezone_dropdown/helpers';

Vue.use(Vuex);

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
      store,
    });
  });

  describe('Deploy freeze table contains components', () => {
    it('contains deploy freeze table', () => {
      expect(wrapper.findComponent(DeployFreezeTable).exists()).toBe(true);
    });

    it('contains deploy freeze modal', () => {
      expect(wrapper.findComponent(DeployFreezeModal).exists()).toBe(true);
    });
  });
});
