const EnvironmentsFolderComponent = require('./environments_folder_view');
require('../../vue_shared/vue_resource_interceptor');

$(() => {
  window.gl = window.gl || {};

  if (gl.EnvironmentsListFolderApp) {
    gl.EnvironmentsListFolderApp.$destroy(true);
  }

  gl.EnvironmentsListFolderApp = new EnvironmentsFolderComponent({
    el: document.querySelector('#environments-folder-list-view'),
  });
});
