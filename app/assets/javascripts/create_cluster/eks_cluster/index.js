import Vue from 'vue';
import Vuex from 'vuex';
import CreateEksCluster from './components/create_eks_cluster.vue';
import createStore from './store';

Vue.use(Vuex);

export default () =>
  new Vue({
    el: '.js-create-eks-cluster-form-container',
    store: createStore(),
    components: {
      CreateEksCluster,
    },
    data() {
      const { gitlabManagedClusterHelpPath } = document.querySelector(this.$options.el).dataset;

      return {
        gitlabManagedClusterHelpPath,
      };
    },
    render(createElement) {
      return createElement('create-eks-cluster', {
        props: {
          gitlabManagedClusterHelpPath: this.gitlabManagedClusterHelpPath,
        },
      });
    },
  });
