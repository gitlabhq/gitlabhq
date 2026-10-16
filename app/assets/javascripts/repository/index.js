import Vue from 'vue';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import initRepositoryPage from './init_repository_page';

Vue.use(PerformancePlugin, {
  components: ['SimpleViewer', 'BlobContent'],
});

export default function setupVueRepositoryList() {
  return initRepositoryPage();
}
