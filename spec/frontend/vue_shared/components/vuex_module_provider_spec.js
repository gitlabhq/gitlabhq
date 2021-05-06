import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VuexModuleProvider from '~/vue_shared/components/vuex_module_provider.vue';

const TestComponent = Vue.extend({
  inject: ['vuexModule'],
  template: `<div data-testid="vuexModule">{{ vuexModule }}</div> `,
});

const TEST_VUEX_MODULE = 'testVuexModule';

describe('~/vue_shared/components/vuex_module_provider', () => {
  let wrapper;

  const findProvidedVuexModule = () => wrapper.find('[data-testid="vuexModule"]').text();

  beforeEach(() => {
    wrapper = mount(VuexModuleProvider, {
      propsData: {
        vuexModule: TEST_VUEX_MODULE,
      },
      slots: {
        default: TestComponent,
      },
    });
  });

  it('provides "vuexModule" set from prop', () => {
    expect(findProvidedVuexModule()).toBe(TEST_VUEX_MODULE);
  });
});
