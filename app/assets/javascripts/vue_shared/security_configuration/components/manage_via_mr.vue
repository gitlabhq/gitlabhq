<script>
import { GlButton } from '@gitlab/ui';
import { featureToMutationMap } from 'ee_else_ce/security_configuration/constants';
import { parseErrorMessage } from '~/lib/utils/error_message';
import { visitUrl } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '~/locale';
import apolloProvider from '../provider';

function mutationSettingsForFeatureType(type) {
  return featureToMutationMap[type];
}

export const i18n = {
  buttonLabel: s__('SecurityConfiguration|Configure with a merge request'),
  noSuccessPathError: s__(
    'SecurityConfiguration|%{featureName} merge request creation mutation failed',
  ),
  genericErrorText: s__(
    `SecurityConfiguration|Something went wrong. Please refresh the page, or try again later.`,
  ),
};

export default {
  apolloProvider,
  components: {
    GlButton,
  },
  inject: ['projectFullPath'],
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
          mutationSettings.getMutationPayload(this.projectFullPath),
        );
        const { errors, successPath } = data[mutationSettings.mutationId];

        if (errors.length > 0) {
          throw new Error(errors[0]);
        }

        // Sending window.gon.uf_error_prefix prefixed messages should happen only in
        // the backend. Hence the code below is an anti-pattern.
        // The issue to refactor: https://gitlab.com/gitlab-org/gitlab/-/issues/397714
        if (!successPath) {
          throw new Error(
            `${window.gon.uf_error_prefix} ${sprintf(this.$options.i18n.noSuccessPathError, {
              featureName: this.feature.name,
            })}`,
          );
        }

        visitUrl(successPath);
      } catch (e) {
        this.$emit('error', parseErrorMessage(e, this.$options.i18n.genericErrorText));
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
  i18n,
};
</script>

<template>
  <gl-button
    v-if="!feature.configured"
    :loading="isLoading"
    :variant="variant"
    :category="category"
    @click="mutate"
    >{{ $options.i18n.buttonLabel }}</gl-button
  >
</template>
