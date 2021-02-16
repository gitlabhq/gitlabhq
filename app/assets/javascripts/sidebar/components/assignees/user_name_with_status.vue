<script>
import { GlSprintf } from '@gitlab/ui';
import { isUserBusy } from '~/set_status_modal/utils';

export default {
  name: 'UserNameWithStatus',
  components: {
    GlSprintf,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    containerClasses: {
      type: String,
      required: false,
      default: '',
    },
    availability: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isBusy() {
      return isUserBusy(this.availability);
    },
  },
};
</script>
<template>
  <span :class="containerClasses">
    <gl-sprintf v-if="isBusy" :message="s__('UserAvailability|%{author} (Busy)')">
      <template #author>{{ name }}</template>
    </gl-sprintf>
    <template v-else>{{ name }}</template>
  </span>
</template>
