import { mount, createLocalVue } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VuexModuleProvider from '~/vue_shared/components/vuex_module_provider.vue';

const TestComponent = Vue.extend({
  inject: ['vuexModule'],
  template: `<div data-testid="vuexModule">{{ vuexModule }}</div> `,
});

const TEST_VUEX_MODULE = 'testVuexModule';

describe('~/vue_shared/components/vuex_module_provider', () => {
  let wrapper;

  const findProvidedVuexModule = () => wrapper.find('[data-testid="vuexModule"]').text();

  const createComponent = (extraParams = {}) => {
    wrapper = mount(VuexModuleProvider, {
      propsData: {
        vuexModule: TEST_VUEX_MODULE,
      },
      slots: {
        default: TestComponent,
      },
      ...extraParams,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('provides "vuexModule" set from prop', () => {
    createComponent();
    expect(findProvidedVuexModule()).toBe(TEST_VUEX_MODULE);
  });

  it('does not blow up when used with vue-apollo', () => {
    // See https://github.com/vuejs/vue-apollo/pull/1153 for details
    const localVue = createLocalVue();
    localVue.use(VueApollo);

    createComponent({ localVue });
    expect(findProvidedVuexModule()).toBe(TEST_VUEX_MODULE);
  });
});
