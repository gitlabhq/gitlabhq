<script>
import { GlForm, GlFormInput, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    buttonLabel: __('Add request manually'),
    inputLabel: __('URL or request ID'),
  },
  components: {
    GlForm,
    GlButton,
    GlFormInput,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      inputEnabled: false,
      urlOrRequestId: '',
    };
  },
  methods: {
    toggleInput() {
      this.inputEnabled = !this.inputEnabled;
    },
    addRequest() {
      this.$emit('add-request', this.urlOrRequestId);
      this.clearForm();
    },
    clearForm() {
      this.urlOrRequestId = '';
      this.toggleInput();
    },
  },
};
</script>
<template>
  <div id="peek-view-add-request" class="view gl-flex">
    <gl-form class="gl-flex gl-items-center" @submit.prevent>
      <gl-button
        v-gl-tooltip.viewport
        class="gl-mr-2"
        category="tertiary"
        variant="link"
        icon="plus"
        size="small"
        :title="$options.i18n.buttonLabel"
        :aria-label="$options.i18n.buttonLabel"
        @click="toggleInput"
      />
      <gl-form-input
        v-if="inputEnabled"
        v-model="urlOrRequestId"
        type="text"
        :placeholder="$options.i18n.inputLabel"
        :aria-label="$options.i18n.inputLabel"
        class="gl-ml-2 !gl-px-3 !gl-py-2"
        @keyup.enter="addRequest"
        @keyup.esc="clearForm"
      />
    </gl-form>
  </div>
</template>
