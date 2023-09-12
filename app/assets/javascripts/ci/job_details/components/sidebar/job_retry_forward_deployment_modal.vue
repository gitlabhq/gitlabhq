<script>
import { GlLink, GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  name: 'JobRetryForwardDeploymentModal',
  components: {
    GlLink,
    GlModal,
  },
  i18n: {
    cancel: __('Cancel'),
    info: s__(
      `Jobs|You're about to retry a job that failed because it attempted to deploy code that is older than the latest deployment.
    Retrying this job could result in overwriting the environment with the older source code.`,
    ),
    areYouSure: s__('Jobs|Are you sure you want to proceed?'),
    moreInfo: __('More information'),
    primaryText: __('Retry job'),
    title: s__('Jobs|Are you sure you want to retry this job?'),
  },
  inject: {
    retryOutdatedJobDocsUrl: {
      default: '',
    },
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
  data() {
    return {
      primaryProps: {
        text: this.$options.i18n.primaryText,
        attributes: {
          'data-method': 'post',
          'data-testid': 'retry-button-modal',
          href: this.href,
          variant: 'danger',
        },
      },
      cancelProps: {
        text: this.$options.i18n.cancel,
        attributes: { category: 'secondary', variant: 'default' },
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
