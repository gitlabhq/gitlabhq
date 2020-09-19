<script>
import { GlButton } from '@gitlab/ui';
import { APPLICATION_STATUS } from '~/clusters/constants';
import { __ } from '~/locale';

const { UPDATING, UNINSTALLING } = APPLICATION_STATUS;

export default {
  components: {
    GlButton,
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
  <gl-button :disabled="disabled" variant="default" :loading="loading">
    {{ label }}
  </gl-button>
</template>
