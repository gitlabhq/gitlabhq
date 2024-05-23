<script>
import { GlModal } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  CANCEL_TEXT,
  CANCEL_JOBS_FAILED_TEXT,
  CANCEL_JOBS_MODAL_TITLE,
  CANCEL_JOBS_WARNING,
  PRIMARY_ACTION_TEXT,
} from '../constants';

export default {
  components: {
    GlModal,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  methods: {
    onSubmit() {
      return axios
        .post(this.url)
        .then((response) => {
          // follow the redirect to refresh the page
          visitUrl(response.request.responseURL);
        })
        .catch((error) => {
          createAlert({
            message: CANCEL_JOBS_FAILED_TEXT,
          });
          throw error;
        });
    },
  },
  primaryAction: {
    text: PRIMARY_ACTION_TEXT,
    attributes: { variant: 'danger' },
  },
  cancelAction: {
    text: CANCEL_TEXT,
  },
  CANCEL_JOBS_WARNING,
  CANCEL_JOBS_MODAL_TITLE,
};
</script>

<template>
  <gl-modal
    :modal-id="modalId"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    :title="$options.CANCEL_JOBS_MODAL_TITLE"
    @primary="onSubmit"
  >
    {{ $options.CANCEL_JOBS_WARNING }}
  </gl-modal>
</template>
