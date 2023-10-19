import { mount } from '@vue/test-utils';
import VuexModuleProvider from '~/vue_shared/components/vuex_module_provider.vue';

const TestComponent = {
  inject: ['vuexModule'],
  template: `<div data-testid="vuexModule">{{ vuexModule }}</div> `,
};

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

  it('provides "vuexModule" set from prop', () => {
    createComponent();
    expect(findProvidedVuexModule()).toBe(TEST_VUEX_MODULE);
  });

  it('provides "vuexModel" set from "vuex-module" prop when using @vue/compat', () => {
    createComponent({
      propsData: { 'vuex-module': TEST_VUEX_MODULE },
    });
    expect(findProvidedVuexModule()).toBe(TEST_VUEX_MODULE);
  });
});
