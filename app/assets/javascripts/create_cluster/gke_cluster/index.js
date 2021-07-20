import Vue from 'vue';
import createFlash from '~/flash';
import GkeMachineTypeDropdown from './components/gke_machine_type_dropdown.vue';
import GkeProjectIdDropdown from './components/gke_project_id_dropdown.vue';
import GkeSubmitButton from './components/gke_submit_button.vue';
import GkeZoneDropdown from './components/gke_zone_dropdown.vue';
import * as CONSTANTS from './constants';
import gapiLoader from './gapi_loader';

import store from './store';

const mountComponent = (entryPoint, component, componentName, extraProps = {}) => {
  const el = document.querySelector(entryPoint);
  if (!el) return false;

  const hiddenInput = el.querySelector('input');

  return new Vue({
    el,
    store,
    components: {
      [componentName]: component,
    },
    render: (createElement) =>
      createElement(componentName, {
        props: {
          fieldName: hiddenInput.getAttribute('name'),
          fieldId: hiddenInput.getAttribute('id'),
          defaultValue: hiddenInput.value,
          ...extraProps,
        },
      }),
  });
};

const mountGkeProjectIdDropdown = () => {
  const entryPoint = '.js-gcp-project-id-dropdown-entry-point';
  const el = document.querySelector(entryPoint);

  mountComponent(entryPoint, GkeProjectIdDropdown, 'gke-project-id-dropdown', {
    docsUrl: el.dataset.docsurl,
  });
};

const mountGkeZoneDropdown = () => {
  mountComponent('.js-gcp-zone-dropdown-entry-point', GkeZoneDropdown, 'gke-zone-dropdown');
};

const mountGkeMachineTypeDropdown = () => {
  mountComponent(
    '.js-gcp-machine-type-dropdown-entry-point',
    GkeMachineTypeDropdown,
    'gke-machine-type-dropdown',
  );
};

const mountGkeSubmitButton = () => {
  mountComponent('.js-gke-cluster-creation-submit-container', GkeSubmitButton, 'gke-submit-button');
};

const gkeDropdownErrorHandler = () => {
  createFlash({
    message: CONSTANTS.GCP_API_ERROR,
  });
};

const initializeGapiClient = (gapi) => () => {
  const el = document.querySelector('.js-gke-cluster-creation');
  if (!el) return false;

  return gapi.client
    .init({
      discoveryDocs: [
        CONSTANTS.GCP_API_CLOUD_BILLING_ENDPOINT,
        CONSTANTS.GCP_API_CLOUD_RESOURCE_MANAGER_ENDPOINT,
        CONSTANTS.GCP_API_COMPUTE_ENDPOINT,
      ],
    })
    .then(() => {
      gapi.client.setToken({ access_token: el.dataset.token });

      mountGkeProjectIdDropdown();
      mountGkeZoneDropdown();
      mountGkeMachineTypeDropdown();
      mountGkeSubmitButton();
    })
    .catch(gkeDropdownErrorHandler);
};

const initGkeDropdowns = () =>
  gapiLoader()
    .then((gapi) => gapi.load('client', initializeGapiClient(gapi)))
    .catch(gkeDropdownErrorHandler);

export default initGkeDropdowns;
