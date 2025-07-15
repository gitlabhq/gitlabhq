import Vue from 'vue';
import GlLicensedFeaturesPlugin from '~/vue_shared/gl_licensed_features_plugin';
import GlFeatureFlagsPlugin from '~/vue_shared/gl_feature_flags_plugin';
import GlAbilitiesPlugin from '~/vue_shared/gl_abilities_plugin';
import Translate from '~/vue_shared/translate';

if (process.env.NODE_ENV !== 'production') {
  Vue.config.productionTip = false;
}

Vue.use(GlLicensedFeaturesPlugin);

Vue.use(GlFeatureFlagsPlugin);
Vue.use(GlAbilitiesPlugin);
Vue.use(Translate);

Vue.config.ignoredElements = ['gl-emoji'];
