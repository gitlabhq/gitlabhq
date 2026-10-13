import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Form from './form.vue';

export default (containerId = '#js-google-cloud-service-accounts') => {
  const element = document.querySelector(containerId);
  const { gcpProjects, refs, cancelPath } = JSON.parse(element.getAttribute('data'));

  return initVueApp({
    el: element,
    name: 'GoogleCloudServiceAccountsFormRoot',
    component: Form,
    props: {
      gcpProjects,
      refs,
      cancelPath,
    },
  });
};
