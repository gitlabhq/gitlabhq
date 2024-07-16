<script>
import { GlToggle, GlAlert, GlLoadingIcon } from '@gitlab/ui';
import SetContainerScanningForRegistry from '~/security_configuration/graphql/set_container_scanning_for_registry.graphql';

export default {
  components: { GlToggle, GlAlert, GlLoadingIcon },
  inject: ['containerScanningForRegistryEnabled', 'projectFullPath'],
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
              namespacePath: this.projectFullPath,
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
        this.$emit('overrideStatus', this.toggleValue);
        this.isRunningMutation = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="errorMessage"
      class="gl-mb-5 gl-mt-2"
      variant="danger"
      @dismiss="errorMessage = ''"
      >{{ errorMessage }}</gl-alert
    >

    <br />

    <div class="gl-display-flex gl-align-items-center">
      <gl-toggle
        :disabled="isRunningMutation"
        :value="toggleValue"
        :label="s__('CVS|Toggle CVS')"
        label-position="hidden"
        @change="toggleCVS"
      />
      <gl-loading-icon v-if="isRunningMutation" inline class="gl-ml-3" />
    </div>
  </div>
</template>
