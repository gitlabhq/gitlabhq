import mountImportProjectsTable from '~/import_entities/import_projects';

import BitbucketServerStatusTable from './components/bitbucket_server_status_table.vue';

const mountElement = document.getElementById('import-projects-mount-element');
mountImportProjectsTable({
  mountElement,
  Component: BitbucketServerStatusTable,
  extraProps: ({ reconfigurePath }) => ({ reconfigurePath }),
});
