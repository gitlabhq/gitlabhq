import Vue from 'vue';
import EnvironmentsFolderComponent from './environments_folder_view.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#environments-folder-list-view',
  components: {
    'environments-folder-app': EnvironmentsFolderComponent,
  },
  render: createElement => createElement('environments-folder-app'),
}));
