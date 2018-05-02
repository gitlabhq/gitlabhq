/* global gapi */
import Vue from 'vue';
import Flash from '~/flash';
import { s__ } from '~/locale';
import GkeProjectIdDropdown from '~/projects/gke_cluster_dropdowns/components/gke_project_id_dropdown.vue';
import GkeZoneDropdown from '~/projects/gke_cluster_dropdowns/components/gke_zone_dropdown.vue';
import GkeMachineTypeDropdown from '~/projects/gke_cluster_dropdowns/components/gke_machine_type_dropdown.vue';

const GCP_API_ERROR =
  'ClusterIntegration|An error occurred when trying to contact the Google Cloud API. Please try again later.';

function mountGkeProjectIdDropdown() {
  const el = document.getElementById('js-gcp-project-id-dropdown-entry-point');
  const hiddenInput = el.querySelector('input');

  if (!el) return;
  // debugger;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      GkeProjectIdDropdown,
    },
    render: createElement =>
      createElement('gke-project-id-dropdown', {
        props: {
          docsUrl: el.dataset.docsurl,
          service: gapi.client.cloudresourcemanager,
          fieldName: hiddenInput.getAttribute('name'),
          fieldId: hiddenInput.getAttribute('id'),
        },
      }),
  });
}

function mountGkeZoneDropdown() {
  const el = document.getElementById('js-gcp-zone-dropdown-entry-point');
  const hiddenInput = el.querySelector('input');

  if (!el) return;
  // debugger;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      GkeZoneDropdown,
    },
    render: createElement =>
      createElement('gke-zone-dropdown', {
        props: {
          service: gapi.client.compute,
          fieldName: hiddenInput.getAttribute('name'),
          fieldId: hiddenInput.getAttribute('id'),
        },
      }),
  });
}

function mountGkeMachineTypeDropdown() {
  const el = document.getElementById('js-gcp-machine-type-dropdown-entry-point');
  const hiddenInput = el.querySelector('input');

  if (!el) return;
  // debugger;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      GkeMachineTypeDropdown,
    },
    render: createElement =>
      createElement('gke-machine-type-dropdown', {
        props: {
          service: gapi.client.compute,
          fieldName: hiddenInput.getAttribute('name'),
          fieldId: hiddenInput.getAttribute('id'),
        },
      }),
  });
}

function initializeGapiClient() {
  const el = document.getElementById('new_cluster');

  gapi.client.setToken({ access_token: el.dataset.token });

  gapi.client
    .load('https://www.googleapis.com/discovery/v1/apis/cloudresourcemanager/v1/rest')
    .then(() => {
      mountGkeProjectIdDropdown();
    })
    .catch(() => {
      Flash(s__(GCP_API_ERROR));
    });

  gapi.client
    .load('https://www.googleapis.com/discovery/v1/apis/compute/v1/rest')
    .then(() => {
      mountGkeZoneDropdown();
      mountGkeMachineTypeDropdown();
    })
    .catch(() => {
      Flash(s__(GCP_API_ERROR));
    });
}

document.addEventListener('DOMContentLoaded', () => {
  if (typeof gapi === 'undefined') {
    Flash(s__(GCP_API_ERROR));
    return false;
  }

  gapi.load('client', initializeGapiClient);
});
