import mountImportProjectsTable from '~/import_entities/import_projects';

document.addEventListener('DOMContentLoaded', () => {
  const mountElement = document.getElementById('import-projects-mount-element');

  mountImportProjectsTable(mountElement);
});
