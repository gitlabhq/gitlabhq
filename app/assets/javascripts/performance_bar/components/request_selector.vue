<script>
import { GlFormSelect } from '@gitlab/ui';

export default {
  components: {
    GlFormSelect,
  },
  props: {
    currentRequest: {
      type: Object,
      required: true,
    },
    requests: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      currentRequestId: this.currentRequest.id,
    };
  },
  watch: {
    currentRequestId(newRequestId) {
      this.$emit('change-current-request', newRequestId);
    },
  },
};
</script>
<template>
  <div id="peek-request-selector" data-testid="request-dropdown" class="view gl-mr-5">
    <gl-form-select v-model="currentRequestId">
      <option
        v-for="request in requests"
        :key="request.id"
        :value="request.id"
        data-testid="request-dropdown-option"
      >
        {{ request.displayName }}
      </option>
    </gl-form-select>
  </div>
</template>
