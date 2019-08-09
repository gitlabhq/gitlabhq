<script>
import $ from 'jquery';
import 'select2';

export default {
  // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  name: 'Select2Select',
  props: {
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
  },

  mounted() {
    $(this.$refs.dropdownInput)
      .val(this.value)
      .select2(this.options)
      .on('change', event => this.$emit('input', event.target.value));
  },

  beforeDestroy() {
    $(this.$refs.dropdownInput).select2('destroy');
  },
};
</script>

<template>
  <input ref="dropdownInput" type="hidden" />
</template>
