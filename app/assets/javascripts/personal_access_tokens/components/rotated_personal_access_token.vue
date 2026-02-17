<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

export default {
  name: 'RotatedPersonalAccessToken',
  components: {
    GlAlert,
    InputCopyToggleVisibility,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  emits: ['input'],
  computed: {
    formInputGroupProps() {
      return {
        'data-testid': this.$options.inputId,
        autocomplete: 'off', // Avoids the revealed token to be added to the search field
      };
    },
  },

  i18n: {
    description: s__(
      "AccessTokens|Token rotated successfully. Make sure you copy your token - you won't be able to access it again.",
    ),
    label: s__('AccessTokens|Your personal access token'),
  },
  inputId: 'rotated-personal-access-token-field',
};
</script>

<template>
  <gl-alert variant="success" class="gl-mb-5" @dismiss="$emit('input', null)">
    <input-copy-toggle-visibility
      :aria-label="$options.i18n.label"
      :label-for="$options.inputId"
      :value="value"
      :form-input-group-props="formInputGroupProps"
      readonly
      size="xl"
      class="gl-mb-0"
    >
      <template #description>
        {{ $options.i18n.description }}
      </template>
    </input-copy-toggle-visibility>
  </gl-alert>
</template>
