<script>
import {
  GlAlert,
  GlTooltipDirective,
  GlCard,
  GlFormRadio,
  GlToggle,
  GlLink,
  GlSkeletonLoader,
  GlIcon,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import SafeHtml from '~/vue_shared/directives/safe_html';
import Tracking from '~/tracking';
import { __, s__ } from '~/locale';
import {
  TRACK_TOGGLE_TRAINING_PROVIDER_ACTION,
  TRACK_TOGGLE_TRAINING_PROVIDER_LABEL,
  TRACK_PROVIDER_LEARN_MORE_CLICK_ACTION,
  TRACK_PROVIDER_LEARN_MORE_CLICK_LABEL,
  TEMP_PROVIDER_LOGOS,
  TEMP_PROVIDER_URLS,
} from '~/security_configuration/constants';
import dismissUserCalloutMutation from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import securityTrainingProvidersQuery from '~/security_configuration/graphql/security_training_providers.query.graphql';
import configureSecurityTrainingProvidersMutation from '~/security_configuration/graphql/configure_security_training_providers.mutation.graphql';
import {
  updateSecurityTrainingCache,
  updateSecurityTrainingOptimisticResponse,
} from '~/security_configuration/graphql/cache_utils';

const i18n = {
  providerQueryErrorMessage: __(
    'Could not fetch training providers. Please refresh the page, or try again later.',
  ),
  configMutationErrorMessage: __(
    'Could not save configuration. Please refresh the page, or try again later.',
  ),
  primaryTraining: s__('SecurityTraining|Primary Training'),
  primaryTrainingDescription: s__(
    'SecurityTraining|Training from this partner takes precedence when more than one training partner is enabled.',
  ),
  unavailableText: s__('SecurityConfiguration|Available with Ultimate'),
};

export default {
  components: {
    GlAlert,
    GlCard,
    GlFormRadio,
    GlToggle,
    GlLink,
    GlSkeletonLoader,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
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
  props: {
    securityTrainingEnabled: {
      type: Boolean,
      required: true,
    },
  },

  data() {
    return {
      errorMessage: '',
      securityTrainingProviders: [],
      hasTouchedConfiguration: false,
    };
  },
  computed: {
    primaryProviderId() {
      return this.securityTrainingProviders.find(({ isPrimary }) => isPrimary)?.id;
    },
    enabledProviders() {
      return this.securityTrainingProviders.filter(({ isEnabled }) => isEnabled);
    },
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
    async toggleProvider(provider) {
      const { isEnabled, isPrimary } = provider;
      const toggledIsEnabled = !isEnabled;

      this.trackProviderToggle(provider.id, toggledIsEnabled);

      // when the current primary provider gets disabled then set the first enabled to be the new primary
      if (!toggledIsEnabled && isPrimary && this.enabledProviders.length > 1) {
        const firstOtherEnabledProvider = this.enabledProviders.find(
          ({ id }) => id !== provider.id,
        );
        this.setPrimaryProvider(firstOtherEnabledProvider);
      }

      this.storeProvider({
        ...provider,
        isEnabled: toggledIsEnabled,
      });
    },
    setPrimaryProvider(provider) {
      this.storeProvider({ ...provider, isPrimary: true });
    },
    async storeProvider(provider) {
      const { id, isEnabled, isPrimary } = provider;
      let nextIsPrimary = isPrimary;

      // if the current provider has been disabled it can't be primary
      if (!isEnabled) {
        nextIsPrimary = false;
      }

      // if the current provider is the only enabled provider it should be primary
      if (isEnabled && !this.enabledProviders.length) {
        nextIsPrimary = true;
      }

      try {
        const {
          data: {
            securityTrainingUpdate: { errors = [] },
          },
        } = await this.$apollo.mutate({
          mutation: configureSecurityTrainingProvidersMutation,
          variables: {
            input: {
              projectPath: this.projectFullPath,
              providerId: id,
              isEnabled,
              isPrimary: nextIsPrimary,
            },
          },
          optimisticResponse: updateSecurityTrainingOptimisticResponse({
            id,
            isEnabled,
            isPrimary: nextIsPrimary,
          }),
          update: updateSecurityTrainingCache({
            query: securityTrainingProvidersQuery,
            variables: { fullPath: this.projectFullPath },
          }),
        });

        if (errors.length > 0) {
          // throwing an error here means we can handle scenarios within the `catch` block below
          throw new Error();
        }

        this.hasTouchedConfiguration = true;
      } catch {
        this.errorMessage = this.$options.i18n.configMutationErrorMessage;
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
    trackProviderLearnMoreClick(providerId) {
      this.track(TRACK_PROVIDER_LEARN_MORE_CLICK_ACTION, {
        label: TRACK_PROVIDER_LEARN_MORE_CLICK_LABEL,
        property: providerId,
      });
    },
  },
  i18n,
  TEMP_PROVIDER_LOGOS,
  TEMP_PROVIDER_URLS,
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" variant="danger" :dismissible="false" class="gl-mb-6">
      {{ errorMessage }}
    </gl-alert>
    <div
      v-if="isLoading"
      class="gl-rounded-base gl-border-1 gl-border-solid gl-border-default gl-bg-white gl-py-6"
    >
      <gl-skeleton-loader :width="350" :height="44">
        <rect width="200" height="8" x="10" y="0" rx="4" />
        <rect width="300" height="8" x="10" y="15" rx="4" />
        <rect width="100" height="8" x="10" y="35" rx="4" />
      </gl-skeleton-loader>
    </div>
    <ul v-else class="gl-m-0 gl-list-none gl-p-0">
      <li v-for="provider in securityTrainingProviders" :key="provider.id" class="gl-mb-6">
        <gl-card :body-class="{ 'gl-bg-subtle': !securityTrainingEnabled }">
          <div class="gl-flex">
            <gl-toggle
              :value="provider.isEnabled"
              :label="__('Training mode')"
              label-position="hidden"
              :disabled="!securityTrainingEnabled"
              data-testid="security-training-toggle"
              :data-qa-training-provider="provider.name"
              @change="toggleProvider(provider)"
            />
            <div v-if="$options.TEMP_PROVIDER_LOGOS[provider.name]" class="gl-ml-4">
              <div
                v-safe-html="$options.TEMP_PROVIDER_LOGOS[provider.name].svg"
                data-testid="provider-logo"
                style="width: 18px"
                role="presentation"
              ></div>
            </div>
            <div class="gl-ml-3">
              <div class="gl-flex gl-justify-between">
                <h3 class="gl-m-0 gl-mb-2 gl-text-lg">
                  {{ provider.name }}
                </h3>
                <span
                  v-if="!securityTrainingEnabled"
                  data-testid="unavailable-text"
                  class="gl-text-subtle"
                >
                  {{ $options.i18n.unavailableText }}
                </span>
              </div>
              <p>
                {{ provider.description }}
                <gl-link
                  v-if="$options.TEMP_PROVIDER_URLS[provider.name]"
                  :href="$options.TEMP_PROVIDER_URLS[provider.name]"
                  target="_blank"
                  @click="trackProviderLearnMoreClick(provider.id)"
                >
                  {{ __('Learn more.') }}
                </gl-link>
              </p>
              <gl-form-radio
                :checked="primaryProviderId"
                :disabled="!securityTrainingEnabled || !provider.isEnabled"
                :value="provider.id"
                @change="setPrimaryProvider(provider)"
              >
                {{ $options.i18n.primaryTraining }}
                <gl-icon
                  v-gl-tooltip="$options.i18n.primaryTrainingDescription"
                  name="information-o"
                  class="gl-ml-2 gl-cursor-help"
                />
              </gl-form-radio>
            </div>
          </div>
        </gl-card>
      </li>
    </ul>
  </div>
</template>
