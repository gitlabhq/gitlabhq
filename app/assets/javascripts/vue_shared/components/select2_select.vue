<script>
import $ from 'jquery';
import 'select2';
import { loadCSSFile } from '~/lib/utils/css_utils';

export default {
  // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
  // eslint-disable-next-line @gitlab/require-i18n-strings
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
    loadCSSFile(gon.select2_css_path)
      .then(() => {
        $(this.$refs.dropdownInput)
          .val(this.value)
          .select2(this.options)
          .on('change', event => this.$emit('input', event.target.value));
      })
      .catch(() => {});
  },

  beforeDestroy() {
    $(this.$refs.dropdownInput).select2('destroy');
  },
};
</script>

<template>
  <input ref="dropdownInput" type="hidden" />
</template>
