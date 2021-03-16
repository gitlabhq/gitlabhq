import Vue from 'vue';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';

if (process.env.NODE_ENV !== 'production') {
  Vue.config.productionTip = false;
}

Vue.use(GlFeatureFlagsPlugin);

Vue.config.ignoredElements = ['gl-emoji'];
