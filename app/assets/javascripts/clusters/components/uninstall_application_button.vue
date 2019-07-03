<script>
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { APPLICATION_STATUS } from '~/clusters/constants';
import { __ } from '~/locale';

const { UPDATING, UNINSTALLING } = APPLICATION_STATUS;

export default {
  components: {
    LoadingButton,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    disabled() {
      return [UNINSTALLING, UPDATING].includes(this.status);
    },
    loading() {
      return this.status === UNINSTALLING;
    },
    label() {
      return this.loading ? __('Uninstalling') : __('Uninstall');
    },
  },
};
</script>

<template>
  <loading-button :label="label" :disabled="disabled" :loading="loading" />
</template>
