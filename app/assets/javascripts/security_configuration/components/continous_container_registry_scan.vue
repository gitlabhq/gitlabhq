<script>
import { GlToggle, GlLink, GlAlert, GlLoadingIcon } from '@gitlab/ui';
import SetContainerScanningForRegistry from '~/security_configuration/graphql/set_container_scanning_for_registry.graphql';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: { GlToggle, GlLink, GlAlert, GlLoadingIcon },
  mixins: [glFeatureFlagsMixin()],
  inject: ['containerScanningForRegistryEnabled', 'projectFullPath'],
  i18n: {
    title: s__('CVS|Continuous Container Scanning'),
    description: s__(
      'CVS|Scan for vulnerabilities when a container image or the advisory database is updated.',
    ),
    learnMore: __('Learn more'),
  },
  props: {
    feature: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      toggleValue: this.containerScanningForRegistryEnabled,
      errorMessage: '',
      isRunningMutation: false,
    };
  },
  computed: {
    isFeatureConfigured() {
      return this.feature.available && this.feature.configured;
    },
  },
  methods: {
    reportError(error) {
      this.errorMessage = error;
    },
    clearError() {
      this.errorMessage = '';
    },
    async toggleCVS(checked) {
      const oldValue = this.toggleValue;

      try {
        this.isRunningMutation = true;
        this.toggleValue = checked;

        this.clearError();

        const { data } = await this.$apollo.mutate({
          mutation: SetContainerScanningForRegistry,
          variables: {
            input: {
              projectPath: this.projectFullPath,
              enable: checked,
            },
          },
        });

        const { errors } = data.setContainerScanningForRegistry;

        if (errors.length > 0) {
          throw new Error(errors[0].message);
        } else {
          this.toggleValue =
            data.setContainerScanningForRegistry.containerScanningForRegistryEnabled;
        }
      } catch (error) {
        this.toggleValue = oldValue;
        this.reportError(error);
      } finally {
        this.isRunningMutation = false;
      }
    },
  },
  CVSHelpPagePath: helpPagePath(
    'user/application_security/continuous_vulnerability_scanning/index',
  ),
};
</script>

<template>
  <div v-if="glFeatures.containerScanningForRegistry">
    <h4 class="gl-font-base gl-mt-6">
      {{ $options.i18n.title }}
    </h4>
    <gl-alert
      v-if="errorMessage"
      class="gl-mb-5 gl-mt-2"
      variant="danger"
      @dismiss="errorMessage = ''"
      >{{ errorMessage }}</gl-alert
    >

    <div class="gl-display-flex gl-align-items-center">
      <gl-toggle
        :disabled="!isFeatureConfigured || isRunningMutation"
        :value="toggleValue"
        :label="s__('CVS|Toggle CVS')"
        label-position="hidden"
        @change="toggleCVS"
      />
      <gl-loading-icon v-if="isRunningMutation" inline class="gl-ml-3" />
    </div>

    <p class="gl-mb-0 gl-mt-5">
      {{ $options.i18n.description }}
      <gl-link :href="$options.CVSHelpPagePath" target="_blank">{{
        $options.i18n.learnMore
      }}</gl-link>
      <br />
    </p>
  </div>
</template>
