import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import GkeSubmitButton from '~/create_cluster/gke_cluster/components/gke_submit_button.vue';

const localVue = createLocalVue();

localVue.use(Vuex);

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
      localVue,
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
