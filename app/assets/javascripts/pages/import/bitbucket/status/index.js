import mountImportProjectsTable from '~/import_entities/import_projects';
import BitbucketStatusTable from '~/import_entities/import_projects/components/bitbucket_status_table.vue';

const mountElement = document.getElementById('import-projects-mount-element');

mountImportProjectsTable({ mountElement, Component: BitbucketStatusTable });
