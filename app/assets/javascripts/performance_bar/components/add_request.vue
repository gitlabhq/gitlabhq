<script>
import { GlForm, GlFormInput, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    buttonLabel: __('Add request manually'),
    inputLabel: __('URL or request ID'),
    submitLabel: __('Add'),
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
    <gl-form class="gl-flex gl-items-center gl-gap-4" @submit.prevent="addRequest">
      <gl-button
        v-gl-tooltip.viewport
        class="!gl-text-neutral-0"
        category="tertiary"
        variant="link"
        icon="plus"
        size="small"
        :title="$options.i18n.buttonLabel"
        :aria-label="$options.i18n.buttonLabel"
        @click="toggleInput"
      />
      <template v-if="inputEnabled">
        <gl-form-input
          v-model="urlOrRequestId"
          type="text"
          :placeholder="$options.i18n.inputLabel"
          :aria-label="$options.i18n.inputLabel"
          class="gl-w-20 !gl-bg-alpha-light-24 !gl-text-neutral-0 !gl-placeholder-neutral-0"
          @keyup.esc="clearForm"
        />
        <gl-button
          v-gl-tooltip.viewport
          category="tertiary"
          type="submit"
          variant="link"
          size="small"
          class="!gl-text-neutral-0"
          :aria-label="$options.i18n.submitLabel"
        >
          {{ $options.i18n.submitLabel }}
        </gl-button>
      </template>
    </gl-form>
  </div>
</template>
