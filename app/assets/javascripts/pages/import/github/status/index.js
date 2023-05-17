import mountImportProjectsTable from '~/import_entities/import_projects';
import GithubStatusTable from '~/import_entities/import_projects/components/github_status_table.vue';

const mountElement = document.getElementById('import-projects-mount-element');

mountImportProjectsTable({
  mountElement,
  Component: GithubStatusTable,
  extraProvide: (dataset) => ({
    statusImportGithubGroupPath: dataset.statusImportGithubGroupPath,
  }),
});
