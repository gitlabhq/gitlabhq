import Vue from 'vue';
import Translate from '../vue_shared/translate';
import '../vue_shared/vue_resource_interceptor';

Vue.use(Translate);

if (process.env.NODE_ENV !== 'production') {
  Vue.config.productionTip = false;
}
