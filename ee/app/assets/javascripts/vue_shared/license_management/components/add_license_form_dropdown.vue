<script>
import $ from 'jquery';
import { KNOWN_LICENSES } from '../constants';

export default {
  name: 'AddLicenseFormDropdown',
  props: {
    placeholder: {
      type: String,
      required: false,
      default: '',
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
      .select2({
        allowClear: true,
        placeholder: this.placeholder,
        createSearchChoice: term => ({ id: term, text: term }),
        createSearchChoicePosition: 'bottom',
        data: KNOWN_LICENSES.map(license => ({ id: license, text: license })),
      })
      .on('change', e => {
        this.$emit('input', e.target.value);
      });
  },
  beforeDestroy() {
    $(this.$refs.dropdownInput).select2('destroy');
  },
};
</script>
<template>
  <input
    ref="dropdownInput"
    type="hidden"
  />
</template>
