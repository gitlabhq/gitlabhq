import Vue from 'vue';
import '../vue_shared/vue_resource_interceptor';

if (process.env.NODE_ENV !== 'production') {
  Vue.config.productionTip = false;
}
