import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import loadClusters from './load_clusters';
import loadMainView from './load_main_view';

Vue.use(GlToast);
Vue.use(VueApollo);

export default () => {
  loadClusters(Vue);
  loadMainView(Vue, VueApollo);
};
