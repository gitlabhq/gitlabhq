import Vue from 'vue';

if (process.env.NODE_ENV !== 'production') {
  Vue.config.productionTip = false;
}

Vue.create = options => new Vue(options);
