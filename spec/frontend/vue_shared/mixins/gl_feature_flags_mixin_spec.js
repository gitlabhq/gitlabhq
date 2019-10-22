import { createLocalVue, shallowMount } from '@vue/test-utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const localVue = createLocalVue();

describe('GitLab Feature Flags Mixin', () => {
  let wrapper;

  beforeEach(() => {
    const gon = {
      features: {
        aFeature: true,
        bFeature: false,
      },
    };

    const component = {
      template: `<span></span>`,
      mixins: [glFeatureFlagsMixin()],
    };

    wrapper = shallowMount(component, {
      localVue,
      provide: {
        glFeatures: { ...(gon.features || {}) },
      },
    });
  });

  it('should provide glFeatures to components', () => {
    expect(wrapper.vm.glFeatures).toEqual({
      aFeature: true,
      bFeature: false,
    });
  });
});
