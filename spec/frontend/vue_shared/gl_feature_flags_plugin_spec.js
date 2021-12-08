import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import GlFeatureFlags from '~/vue_shared/gl_feature_flags_plugin';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

describe('GitLab Feature Flags Plugin', () => {
  beforeEach(() => {
    window.gon = {
      features: {
        aFeature: true,
        bFeature: false,
      },
      licensed_features: {
        cFeature: true,
        dFeature: false,
      },
    };

    Vue.use(GlFeatureFlags);
  });

  it('should provide glFeatures to components', () => {
    const component = {
      template: `<span></span>`,
      inject: ['glFeatures'],
    };
    const wrapper = shallowMount(component);
    expect(wrapper.vm.glFeatures).toEqual({
      aFeature: true,
      bFeature: false,
      cFeature: true,
      dFeature: false,
    });
  });

  it('should integrate with the glFeatureMixin', () => {
    const component = {
      template: `<span></span>`,
      mixins: [glFeatureFlagsMixin()],
    };
    const wrapper = shallowMount(component);
    expect(wrapper.vm.glFeatures).toEqual({
      aFeature: true,
      bFeature: false,
      cFeature: true,
      dFeature: false,
    });
  });
});
