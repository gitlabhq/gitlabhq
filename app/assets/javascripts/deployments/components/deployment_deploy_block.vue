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
        ? { name: 'check-circle-filled', variant: 'success' }
        : { name: 'timer', variant: 'current' };
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
      <span v-if="canPlay" class="gl-ml-4 gl-grow gl-font-bold">{{
        s__('Deployment|Ready to be deployed.')
      }}</span>
      <span v-else class="gl-ml-4">
        <span class="gl-font-bold">{{ s__('Deployment|Waiting to be deployed.') }}</span>
        {{ s__('Deployment|You are not authorized to trigger this deployment.') }}
      </span>

      <gl-button v-if="canPlay" :loading="loading" variant="confirm" @click="playJob">
        {{ s__('Deployment|Deploy') }}
      </gl-button>
    </template>
  </div>
</template>
