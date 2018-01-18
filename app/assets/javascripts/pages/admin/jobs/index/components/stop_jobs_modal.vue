<script>
  import axios from '~/lib/utils/axios_utils';
  import Flash from '~/flash';
  import modal from '~/vue_shared/components/modal.vue';
  import { s__ } from '~/locale';
  import { redirectTo } from '~/lib/utils/url_utility';

  export default {
    components: {
      modal,
    },
    props: {
      url: {
        type: String,
        required: true,
      },
    },
    computed: {
      text() {
        return s__('AdminArea|You’re about to stop all jobs. This will halt all current jobs that are running.');
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
            Flash(s__('AdminArea|Stopping jobs failed'));
            throw error;
          });
      },
    },
  };
</script>

<template>
  <modal
    id="stop-jobs-modal"
    :title="s__('AdminArea|Stop all jobs?')"
    :text="text"
    kind="danger"
    :primary-button-label="s__('AdminArea|Stop jobs')"
    @submit="onSubmit" />
</template>
