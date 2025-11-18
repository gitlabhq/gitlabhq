<script>
import { s__ } from '~/locale';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

export default {
  name: 'RegistrationToken',
  components: {
    InputCopyToggleVisibility,
  },
  i18n: {
    registrationToken: s__('Runners|Registration token'),
  },
  props: {
    inputId: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    formInputGroupProps() {
      return {
        id: this.inputId,
      };
    },
  },
};
</script>
<template>
  <input-copy-toggle-visibility
    class="gl-m-0"
    :value="value"
    :label="$options.i18n.registrationToken"
    :label-for="inputId"
    :copy-button-title="s__('Runners|Copy registration token')"
    :copy-button-toast-message="s__('Runners|Registration token copied to clipboard.')"
    :form-input-group-props="formInputGroupProps"
    readonly
  >
    <template v-for="slot in Object.keys($scopedSlots)" #[slot]>
      <slot :name="slot"></slot>
    </template>
  </input-copy-toggle-visibility>
</template>
