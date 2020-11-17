<script>
import { AVAILABILITY_STATUS, isUserBusy, isValidAvailibility } from '../utils';

export default {
  name: 'UserAvailabilityStatus',
  props: {
    availability: {
      type: String,
      required: true,
      validator: isValidAvailibility,
    },
  },
  computed: {
    isBusy() {
      const { availability = AVAILABILITY_STATUS.NOT_SET } = this;
      return isUserBusy(availability);
    },
  },
};
</script>

<template>
  <span v-if="isBusy" class="gl-font-weight-normal gl-text-gray-500">{{
    s__('UserAvailability|(Busy)')
  }}</span>
</template>
