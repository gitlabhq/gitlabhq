<script>
import { GlLink, GlModal } from '@gitlab/ui';
import { JOB_RETRY_FORWARD_DEPLOYMENT_MODAL } from '../constants';

export default {
  name: 'JobRetryForwardDeploymentModal',
  components: {
    GlLink,
    GlModal,
  },
  i18n: {
    ...JOB_RETRY_FORWARD_DEPLOYMENT_MODAL,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    href: {
      type: String,
      required: true,
    },
  },
  inject: {
    retryOutdatedJobDocsUrl: {
      default: '',
    },
  },
  data() {
    return {
      primaryProps: {
        text: this.$options.i18n.primaryText,
        attributes: [
          {
            'data-method': 'post',
            'data-testid': 'retry-button-modal',
            href: this.href,
            variant: 'danger',
          },
        ],
      },
      cancelProps: {
        text: this.$options.i18n.cancel,
        attributes: [{ category: 'secondary', variant: 'default' }],
      },
    };
  },
};
</script>

<template>
  <gl-modal
    :action-cancel="cancelProps"
    :action-primary="primaryProps"
    :modal-id="modalId"
    :title="$options.i18n.title"
  >
    <p>
      {{ $options.i18n.info }}
      <gl-link v-if="retryOutdatedJobDocsUrl" :href="retryOutdatedJobDocsUrl" target="_blank">
        {{ $options.i18n.moreInfo }}
      </gl-link>
    </p>
    <p>{{ $options.i18n.areYouSure }}</p>
  </gl-modal>
</template>
