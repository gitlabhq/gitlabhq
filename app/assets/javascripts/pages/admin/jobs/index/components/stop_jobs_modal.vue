<script>
import { GlModal } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';

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
      return s__(
        'AdminArea|You’re about to stop all jobs.This will halt all current jobs that are running.',
      );
    },
  },
  methods: {
    onSubmit() {
      return axios
        .post(this.url)
        .then((response) => {
          // follow the rediect to refresh the page
          redirectTo(response.request.responseURL);
        })
        .catch((error) => {
          createFlash({
            message: s__('AdminArea|Stopping jobs failed'),
          });
          throw error;
        });
    },
  },
  primaryAction: {
    text: s__('AdminArea|Stop jobs'),
    attributes: [{ variant: 'danger' }],
  },
  cancelAction: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal
    modal-id="stop-jobs-modal"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    @primary="onSubmit"
  >
    <template #modal-title>{{ s__('AdminArea|Stop all jobs?') }}</template>
    {{ text }}
  </gl-modal>
</template>
