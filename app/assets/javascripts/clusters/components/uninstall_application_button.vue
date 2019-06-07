<script>
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { APPLICATION_STATUS } from '~/clusters/constants';

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
      return this.loading ? this.__('Uninstalling') : this.__('Uninstall');
    },
  },
};
</script>

<template>
  <loading-button :label="label" :disabled="disabled" :loading="loading" />
</template>
