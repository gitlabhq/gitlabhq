import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import GlLicensedFeaturesPlugin from '~/vue_shared/gl_licensed_features_plugin';
import glLicensedFeaturesMixin from '~/vue_shared/mixins/gl_licensed_feature_mixin';

describe('GitLab Licenced Feature Flags Plugin', () => {
  beforeEach(() => {
    window.gon = {
      licensed_features: {
        aFeature: true,
        bFeature: false,
      },
    };

    Vue.use(GlLicensedFeaturesPlugin);
  });

  it('should provide glLicensedFeatures to components', () => {
    const component = {
      template: `<span></span>`,
      inject: ['glLicensedFeatures'],
    };
    const wrapper = shallowMount(component);
    expect(wrapper.vm.glLicensedFeatures).toEqual({
      aFeature: true,
      bFeature: false,
    });
  });

  it('should integrate with the glLicensedFeaturesMixin', () => {
    const component = {
      template: `<span></span>`,
      mixins: [glLicensedFeaturesMixin()],
    };
    const wrapper = shallowMount(component);
    expect(wrapper.vm.glLicensedFeatures).toEqual({
      aFeature: true,
      bFeature: false,
    });
  });
});
