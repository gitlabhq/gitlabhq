<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { integrationLevels } from '~/integrations/constants';
import ConfirmationModal from './confirmation_modal.vue';
import ResetConfirmationModal from './reset_confirmation_modal.vue';

export default {
  name: 'IntegrationFormActions',
  components: {
    GlButton,
    ConfirmationModal,
    ResetConfirmationModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    hasSections: {
      type: Boolean,
      required: true,
    },
    isSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
    isTesting: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResetting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['propsSource']),
    ...mapState(['customState']),
    isInstanceOrGroupLevel() {
      return (
        this.customState.integrationLevel === integrationLevels.INSTANCE ||
        this.customState.integrationLevel === integrationLevels.GROUP
      );
    },
    showResetButton() {
      return (
        this.isInstanceOrGroupLevel &&
        this.propsSource.resetPath &&
        this.propsSource.manualActivation
      );
    },
    showTestButton() {
      return this.propsSource.canTest;
    },
    disableButtons() {
      return Boolean(this.isSaving || this.isResetting || this.isTesting);
    },
  },
  methods: {
    onSaveClick() {
      this.$emit('save');
    },
    onTestClick() {
      this.$emit('test');
    },
    onResetClick() {
      this.$emit('reset');
    },
  },
};
</script>
<template>
  <section class="gl-flex gl-flex-wrap gl-justify-between gl-gap-3">
    <div class="gl-flex gl-flex-wrap gl-gap-3">
      <template v-if="isInstanceOrGroupLevel">
        <gl-button
          v-gl-modal.confirmSaveIntegration
          category="primary"
          variant="confirm"
          :loading="isSaving"
          :disabled="disableButtons"
          data-testid="save-changes-button"
        >
          {{ __('Save changes') }}
        </gl-button>
        <confirmation-modal @submit="onSaveClick" />
      </template>
      <gl-button
        v-else
        category="primary"
        variant="confirm"
        type="submit"
        :loading="isSaving"
        :disabled="disableButtons"
        data-testid="save-changes-button"
        @click.prevent="onSaveClick"
      >
        {{ __('Save changes') }}
      </gl-button>

      <gl-button
        v-if="showTestButton"
        category="secondary"
        variant="confirm"
        :loading="isTesting"
        :disabled="disableButtons"
        data-testid="test-button"
        @click.prevent="onTestClick"
      >
        {{ __('Test settings') }}
      </gl-button>

      <gl-button
        :href="propsSource.cancelPath"
        data-testid="cancel-button"
        :disabled="disableButtons"
        >{{ __('Cancel') }}</gl-button
      >
    </div>

    <template v-if="showResetButton">
      <gl-button
        v-gl-modal.confirmResetIntegration
        category="secondary"
        variant="danger"
        :loading="isResetting"
        :disabled="disableButtons"
        data-testid="reset-button"
      >
        {{ __('Reset') }}
      </gl-button>

      <reset-confirmation-modal @reset="onResetClick" />
    </template>
  </section>
</template>
