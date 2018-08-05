import Vue from 'vue';
import '../vue_shared/vue_resource_interceptor';

Vue.config.performance = true;

if (process.env.NODE_ENV !== 'production') {
  Vue.config.productionTip = false;
}
