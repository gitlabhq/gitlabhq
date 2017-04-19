import Vue from 'vue';
import EnvironmentsFolderComponent from './environments_folder_view.vue';

$(() => {
  new Vue({ // eslint-disable-line
    el: '#js-environments-folder-list-view',
    components: {
      'environments-list-folder-component': EnvironmentsFolderComponent,
    },
    render: createElement => createElement('environments-list-folder-component'),
  });
});
