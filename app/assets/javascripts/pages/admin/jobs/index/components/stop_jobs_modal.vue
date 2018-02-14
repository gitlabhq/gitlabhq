<script>
  import axios from '~/lib/utils/axios_utils';
  import createFlash from '~/flash';
  import GlModal from '~/vue_shared/components/gl_modal.vue';
  import { redirectTo } from '~/lib/utils/url_utility';
  import { s__ } from '~/locale';

  export default {
    components: {
      GlModal,
    },
    props: {
      url: {
        type: String,
        required: true,
      },
    },
    computed: {
      text() {
        return s__('AdminArea|You’re about to stop all jobs.This will halt all current jobs that are running.');
      },
    },
    methods: {
      onSubmit() {
        return axios.post(this.url)
          .then((response) => {
            // follow the rediect to refresh the page
            redirectTo(response.request.responseURL);
          })
          .catch((error) => {
            createFlash(s__('AdminArea|Stopping jobs failed'));
            throw error;
          });
      },
    },
  };
</script>

<template>
  <gl-modal
    id="stop-jobs-modal"
    :header-title-text="s__('AdminArea|Stop all jobs?')"
    footer-primary-button-variant="danger"
    :footer-primary-button-text="s__('AdminArea|Stop jobs')"
    @submit="onSubmit"
  >
    {{ text }}
  </gl-modal>
</template>
