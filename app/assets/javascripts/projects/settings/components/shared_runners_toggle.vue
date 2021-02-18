<script>
import { GlAlert, GlToggle, GlTooltip } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

const DEFAULT_ERROR_MESSAGE = __('An error occurred while updating the configuration.');

export default {
  components: {
    GlAlert,
    GlToggle,
    GlTooltip,
  },
  props: {
    isDisabledAndUnoverridable: {
      type: Boolean,
      required: true,
    },
    isEnabled: {
      type: Boolean,
      required: true,
    },
    updatePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      isSharedRunnerEnabled: false,
      errorMessage: null,
    };
  },
  created() {
    this.isSharedRunnerEnabled = this.isEnabled;
  },
  methods: {
    toggleSharedRunners() {
      this.isLoading = true;
      this.errorMessage = null;

      axios
        .post(this.updatePath)
        .then(() => {
          this.isLoading = false;
          this.isSharedRunnerEnabled = !this.isSharedRunnerEnabled;
        })
        .catch((error) => {
          this.isLoading = false;
          this.errorMessage = error.response?.data?.error || DEFAULT_ERROR_MESSAGE;
        });
    },
  },
};
</script>

<template>
  <div>
    <section class="gl-mt-5">
      <gl-alert v-if="errorMessage" class="gl-mb-3" variant="danger" :dismissible="false">
        {{ errorMessage }}
      </gl-alert>
      <div ref="sharedRunnersToggle">
        <gl-toggle
          :disabled="isDisabledAndUnoverridable"
          :is-loading="isLoading"
          :label="__('Enable shared runners for this project')"
          :value="isSharedRunnerEnabled"
          data-testid="toggle-shared-runners"
          @change="toggleSharedRunners"
        />
      </div>
      <gl-tooltip v-if="isDisabledAndUnoverridable" :target="() => $refs.sharedRunnersToggle">
        {{ __('Shared runners are disabled on group level') }}
      </gl-tooltip>
    </section>
  </div>
</template>
