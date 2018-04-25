import Vue from 'vue';
import { isProductionEnvironment } from '~/environment';
import '../vue_shared/vue_resource_interceptor';

if (!isProductionEnvironment()) {
  Vue.config.productionTip = false;
}
