<script>
import { GlModal } from '@gitlab/ui';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import {
  CANCEL_TEXT,
  STOP_JOBS_MODAL_ID,
  STOP_JOBS_FAILED_TEXT,
  STOP_JOBS_MODAL_TITLE,
  STOP_JOBS_WARNING,
  PRIMARY_ACTION_TEXT,
} from './constants';

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
  methods: {
    onSubmit() {
      return axios
        .post(this.url)
        .then((response) => {
          // follow the rediect to refresh the page
          redirectTo(response.request.responseURL);
        })
        .catch((error) => {
          createAlert({
            message: STOP_JOBS_FAILED_TEXT,
          });
          throw error;
        });
    },
  },
  primaryAction: {
    text: PRIMARY_ACTION_TEXT,
    attributes: [{ variant: 'danger' }],
  },
  cancelAction: {
    text: CANCEL_TEXT,
  },
  STOP_JOBS_WARNING,
  STOP_JOBS_MODAL_ID,
  STOP_JOBS_MODAL_TITLE,
};
</script>

<template>
  <gl-modal
    :modal-id="$options.STOP_JOBS_MODAL_ID"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    @primary="onSubmit"
  >
    <template #modal-title>{{ $options.STOP_JOBS_MODAL_TITLE }}</template>
    {{ $options.STOP_JOBS_WARNING }}
  </gl-modal>
</template>
