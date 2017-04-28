import Vue from 'vue';
import EnvironmentsFolderComponent from './environments_folder_view.vue';

<<<<<<< HEAD
document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#environments-folder-list-view',
  components: {
    'environments-folder-app': EnvironmentsFolderComponent,
  },
  render: createElement => createElement('environments-folder-app'),
}));
=======
document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#environments-folder-list-view',
    components: {
      'environments-folder-app': EnvironmentsFolderComponent,
    },
    render: createElement => createElement('environments-folder-app'),
  });
});
>>>>>>> upstream/master
