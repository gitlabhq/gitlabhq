<script>
import { GlButton } from '@gitlab/ui';
import { featureToMutationMap } from 'ee_else_ce/security_configuration/components/constants';
import { redirectTo } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '~/locale';
import apolloProvider from '../provider';

function mutationSettingsForFeatureType(type) {
  return featureToMutationMap[type];
}

export default {
  apolloProvider,
  components: {
    GlButton,
  },
  inject: ['projectPath'],
  props: {
    feature: {
      type: Object,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: 'confirm',
    },
    category: {
      type: String,
      required: false,
      default: 'secondary',
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    mutationSettings() {
      return mutationSettingsForFeatureType(this.feature.type);
    },
  },
  methods: {
    async mutate() {
      this.isLoading = true;
      try {
        const { mutationSettings } = this;
        const { data } = await this.$apollo.mutate(
          mutationSettings.getMutationPayload(this.projectPath),
        );
        const { errors, successPath } = data[mutationSettings.mutationId];

        if (errors.length > 0) {
          throw new Error(errors[0]);
        }

        if (!successPath) {
          throw new Error(
            sprintf(this.$options.i18n.noSuccessPathError, { featureName: this.feature.name }),
          );
        }

        redirectTo(successPath);
      } catch (e) {
        this.$emit('error', e.message);
        this.isLoading = false;
      }
    },
  },
  /**
   * Returns a boolean representing whether this component can be rendered for
   * the given feature. Useful for parent components to determine whether or
   * not to render this component.
   * @param {Object} feature The feature to check.
   * @returns {boolean}
   */
  canRender(feature) {
    const { available, configured, canEnableByMergeRequest, type } = feature;
    return (
      canEnableByMergeRequest &&
      available &&
      !configured &&
      Boolean(mutationSettingsForFeatureType(type))
    );
  },
  i18n: {
    buttonLabel: s__('SecurityConfiguration|Configure via Merge Request'),
    noSuccessPathError: s__(
      'SecurityConfiguration|%{featureName} merge request creation mutation failed',
    ),
  },
};
</script>

<template>
  <gl-button
    v-if="!feature.configured"
    data-testid="configure-via-mr-button"
    :loading="isLoading"
    :variant="variant"
    :category="category"
    @click="mutate"
    >{{ $options.i18n.buttonLabel }}</gl-button
  >
</template>
