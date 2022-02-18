import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GkeSubmitButton from '~/create_cluster/gke_cluster/components/gke_submit_button.vue';

Vue.use(Vuex);

describe('GkeSubmitButton', () => {
  let wrapper;
  let store;
  let hasValidData;

  const buildStore = () =>
    new Vuex.Store({
      getters: {
        hasValidData,
      },
    });

  const buildWrapper = () =>
    shallowMount(GkeSubmitButton, {
      store,
    });

  const bootstrap = () => {
    store = buildStore();
    wrapper = buildWrapper();
  };

  beforeEach(() => {
    hasValidData = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('is disabled when hasValidData is false', () => {
    hasValidData.mockReturnValueOnce(false);
    bootstrap();

    expect(wrapper.attributes('disabled')).toBe('disabled');
  });

  it('is not disabled when hasValidData is true', () => {
    hasValidData.mockReturnValueOnce(true);
    bootstrap();

    expect(wrapper.attributes('disabled')).toBeFalsy();
  });
});
