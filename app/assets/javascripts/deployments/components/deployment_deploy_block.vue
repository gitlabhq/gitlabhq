<script>
import { GlAlert, GlIcon, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import deployMutation from '../graphql/mutations/deploy.mutation.graphql';

export default {
  components: {
    GlAlert,
    GlIcon,
    GlButton,
  },
  props: {
    deployment: { type: Object, required: true },
  },
  data() {
    return {
      errorMessage: '',
      loading: false,
    };
  },
  computed: {
    isPlayable() {
      return this.deployment.job?.playable;
    },
    canPlay() {
      return this.deployment.job?.canPlayJob;
    },
    icon() {
      return this.canPlay
        ? { name: 'check-circle-filled', class: 'gl-fill-green-500' }
        : { name: 'timer', class: 'gl-fill-current' };
    },
    text() {
      return this.canPlay ? this.$options.i18n.ready : this.$options.i18n.waiting;
    },
    hasError() {
      return Boolean(this.errorMessage);
    },
  },
  methods: {
    playJob() {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation: deployMutation,
          variables: {
            input: {
              id: this.deployment.job.id,
            },
          },
        })
        .then(({ data }) => {
          const { errors = [] } = data.jobPlay;
          if (errors.length) {
            [this.errorMessage] = errors;
          }
        })
        .catch((error) => {
          this.errorMessage = this.$options.i18n.genericError;
          captureException(error);
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
  i18n: {
    waiting: s__('Deployment|Waiting to be deployed.'),
    ready: s__('Deployment|Ready to be deployed.'),
    deploy: s__('Deployment|Deploy'),
    genericError: s__(
      'Deployment|Something went wrong starting the deployment. Please try again later.',
    ),
  },
};
</script>
<template>
  <div v-if="isPlayable" class="gl-border gl-flex gl-items-center gl-rounded-base gl-p-5">
    <gl-alert v-if="hasError" variant="danger" class="gl-w-full" @dismiss="errorMessage = ''">
      {{ errorMessage }}
    </gl-alert>
    <template v-else>
      <gl-icon v-bind="icon" />
      <span class="gl-ml-4 gl-grow gl-font-bold">{{ text }}</span>
      <gl-button v-if="canPlay" :loading="loading" variant="confirm" @click="playJob">
        {{ $options.i18n.deploy }}
      </gl-button>
    </template>
  </div>
</template>
