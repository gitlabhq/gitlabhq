/* global gapi */
import Vue from 'vue';
import Flash from '~/flash';
import GkeProjectIdDropdown from './components/gke_project_id_dropdown.vue';
import GkeZoneDropdown from './components/gke_zone_dropdown.vue';
import GkeMachineTypeDropdown from './components/gke_machine_type_dropdown.vue';
import * as CONSTANTS from './constants';

const mountGkeProjectIdDropdown = () => {
  const el = document.querySelector('.js-gcp-project-id-dropdown-entry-point');
  const hiddenInput = el.querySelector('input');

  if (!el) return false;

  return new Vue({
    el,
    components: {
      GkeProjectIdDropdown,
    },
    render: createElement =>
      createElement('gke-project-id-dropdown', {
        props: {
          docsUrl: el.dataset.docsurl,
          fieldName: hiddenInput.getAttribute('name'),
          fieldId: hiddenInput.getAttribute('id'),
          defaultValue: hiddenInput.value,
        },
      }),
  });
};

const mountGkeZoneDropdown = () => {
  const el = document.querySelector('.js-gcp-zone-dropdown-entry-point');
  const hiddenInput = el.querySelector('input');

  if (!el) return false;

  return new Vue({
    el,
    components: {
      GkeZoneDropdown,
    },
    render: createElement =>
      createElement('gke-zone-dropdown', {
        props: {
          fieldName: hiddenInput.getAttribute('name'),
          fieldId: hiddenInput.getAttribute('id'),
          defaultValue: hiddenInput.value,
        },
      }),
  });
};

const mountGkeMachineTypeDropdown = () => {
  const el = document.querySelector('.js-gcp-machine-type-dropdown-entry-point');
  const hiddenInput = el.querySelector('input');

  if (!el) return false;

  return new Vue({
    el,
    components: {
      GkeMachineTypeDropdown,
    },
    render: createElement =>
      createElement('gke-machine-type-dropdown', {
        props: {
          fieldName: hiddenInput.getAttribute('name'),
          fieldId: hiddenInput.getAttribute('id'),
          defaultValue: hiddenInput.value,
        },
      }),
  });
};

const gkeDropdownErrorHandler = () => {
  Flash(CONSTANTS.GCP_API_ERROR);
};

const initializeGapiClient = () => {
  const el = document.querySelector('.js-gke-cluster-creation');

  gapi.client.setToken({ access_token: el.dataset.token });
  delete el.dataset.token;

  gapi.client
    .load(CONSTANTS.GCP_API_CLOUD_RESOURCE_MANAGER_ENDPOINT)
    .then(() => {
      mountGkeProjectIdDropdown();
    })
    .catch(gkeDropdownErrorHandler);

  gapi.client
    .load(CONSTANTS.GCP_API_COMPUTE_ENDPOINT)
    .then(() => {
      mountGkeZoneDropdown();
      mountGkeMachineTypeDropdown();
    })
    .catch(gkeDropdownErrorHandler);
};

const initGkeDropdowns = () => {
  if (typeof gapi === 'undefined') {
    gkeDropdownErrorHandler();
    return false;
  }

  return gapi.load('client', initializeGapiClient);
};

export default initGkeDropdowns;
