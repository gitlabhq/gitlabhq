<script>
import { GlAlert, GlCard, GlToggle, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Tracking from '~/tracking';
import { __ } from '~/locale';
import {
  TRACK_TOGGLE_TRAINING_PROVIDER_ACTION,
  TRACK_TOGGLE_TRAINING_PROVIDER_LABEL,
} from '~/security_configuration/constants';
import dismissUserCalloutMutation from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import securityTrainingProvidersQuery from '../graphql/security_training_providers.query.graphql';
import configureSecurityTrainingProvidersMutation from '../graphql/configure_security_training_providers.mutation.graphql';

const i18n = {
  providerQueryErrorMessage: __(
    'Could not fetch training providers. Please refresh the page, or try again later.',
  ),
  configMutationErrorMessage: __(
    'Could not save configuration. Please refresh the page, or try again later.',
  ),
};

export default {
  components: {
    GlAlert,
    GlCard,
    GlToggle,
    GlLink,
    GlSkeletonLoader,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectFullPath'],
  apollo: {
    securityTrainingProviders: {
      query: securityTrainingProvidersQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
        };
      },
      update({ project }) {
        return project?.securityTrainingProviders;
      },
      error() {
        this.errorMessage = this.$options.i18n.providerQueryErrorMessage;
      },
    },
  },
  data() {
    return {
      errorMessage: '',
      toggleLoading: false,
      securityTrainingProviders: [],
      hasTouchedConfiguration: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.securityTrainingProviders.loading;
    },
  },
  created() {
    const unwatchConfigChance = this.$watch('hasTouchedConfiguration', () => {
      this.dismissFeaturePromotionCallout();
      unwatchConfigChance();
    });
  },
  methods: {
    async dismissFeaturePromotionCallout() {
      try {
        const {
          data: {
            userCalloutCreate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: dismissUserCalloutMutation,
          variables: {
            input: {
              featureName: 'security_training_feature_promotion',
            },
          },
        });

        // handle errors reported from the backend
        if (errors?.length > 0) {
          throw new Error(errors[0]);
        }
      } catch (e) {
        Sentry.captureException(e);
      }
    },
    toggleProvider(selectedProviderId) {
      const toggledProviders = this.securityTrainingProviders.map((provider) => ({
        ...provider,
        ...(provider.id === selectedProviderId && { isEnabled: !provider.isEnabled }),
      }));

      const enabledProviderIds = toggledProviders
        .filter(({ isEnabled }) => isEnabled)
        .map(({ id }) => id);

      const { isEnabled: selectedProviderIsEnabled } = toggledProviders.find(
        (provider) => provider.id === selectedProviderId,
      );

      this.trackProviderToggle(selectedProviderId, selectedProviderIsEnabled);
      this.storeEnabledProviders(enabledProviderIds);
    },
    async storeEnabledProviders(enabledProviderIds) {
      this.toggleLoading = true;

      try {
        const {
          data: {
            configureSecurityTrainingProviders: { errors = [] },
          },
        } = await this.$apollo.mutate({
          mutation: configureSecurityTrainingProvidersMutation,
          variables: {
            input: {
              enabledProviders: enabledProviderIds,
              fullPath: this.projectFullPath,
            },
          },
        });

        if (errors.length > 0) {
          // throwing an error here means we can handle scenarios within the `catch` block below
          throw new Error();
        }

        this.hasTouchedConfiguration = true;
      } catch {
        this.errorMessage = this.$options.i18n.configMutationErrorMessage;
      } finally {
        this.toggleLoading = false;
      }
    },
    trackProviderToggle(providerId, providerIsEnabled) {
      this.track(TRACK_TOGGLE_TRAINING_PROVIDER_ACTION, {
        label: TRACK_TOGGLE_TRAINING_PROVIDER_LABEL,
        property: providerId,
        extra: {
          providerIsEnabled,
        },
      });
    },
  },
  i18n,
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" variant="danger" :dismissible="false" class="gl-mb-6">
      {{ errorMessage }}
    </gl-alert>
    <div
      v-if="isLoading"
      class="gl-bg-white gl-py-6 gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100"
    >
      <gl-skeleton-loader :width="350" :height="44">
        <rect width="200" height="8" x="10" y="0" rx="4" />
        <rect width="300" height="8" x="10" y="15" rx="4" />
        <rect width="100" height="8" x="10" y="35" rx="4" />
      </gl-skeleton-loader>
    </div>
    <ul v-else class="gl-list-style-none gl-m-0 gl-p-0">
      <li
        v-for="{ id, isEnabled, name, description, url } in securityTrainingProviders"
        :key="id"
        class="gl-mb-6"
      >
        <gl-card>
          <div class="gl-display-flex">
            <gl-toggle
              :value="isEnabled"
              :label="__('Training mode')"
              label-position="hidden"
              :is-loading="toggleLoading"
              @change="toggleProvider(id)"
            />
            <div class="gl-ml-5">
              <h3 class="gl-font-lg gl-m-0 gl-mb-2">{{ name }}</h3>
              <p>
                {{ description }}
                <gl-link :href="url" target="_blank">{{ __('Learn more.') }}</gl-link>
              </p>
            </div>
          </div>
        </gl-card>
      </li>
    </ul>
  </div>
</template>
