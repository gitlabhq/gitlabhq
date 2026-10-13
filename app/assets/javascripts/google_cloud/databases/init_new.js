import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Form from './cloudsql/create_instance_form.vue';

export default () => {
  const element = document.querySelector('#js-google-cloud-databases-cloudsql-form');
  const { gcpProjects, refs, cancelPath, formTitle, formDescription, databaseVersions, tiers } =
    JSON.parse(element.getAttribute('data'));

  return initVueApp({
    el: element,
    name: 'GoogleCloudDatabasesFormRoot',
    component: Form,
    props: {
      gcpProjects,
      refs,
      cancelPath,
      formTitle,
      formDescription,
      databaseVersions,
      tiers,
    },
  });
};
