import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

if (process.env.NODE_ENV !== 'production') {
  Vue.config.productionTip = false;
}
