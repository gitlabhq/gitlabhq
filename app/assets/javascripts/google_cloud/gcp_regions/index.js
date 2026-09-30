import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Form from './form.vue';

export default (containerId = '#js-google-cloud-gcp-regions') => {
  const element = document.querySelector(containerId);
  const { availableRegions, refs, cancelPath } = JSON.parse(element.getAttribute('data'));

  return initVueApp({
    el: element,
    name: 'GoogleCloudGcpRegionsFormRoot',
    component: Form,
    props: {
      availableRegions,
      refs,
      cancelPath,
    },
  });
};
