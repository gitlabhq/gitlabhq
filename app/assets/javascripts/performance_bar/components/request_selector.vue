<script>
export default {
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
  methods: {
    truncatedUrl(requestUrl) {
      const components = requestUrl.replace(/\/$/, '').split('/');
      let truncated = components[components.length - 1];

      if (truncated.match(/^\d+$/)) {
        truncated = `${components[components.length - 2]}/${truncated}`;
      }

      return truncated;
    },
  },
};
</script>
<template>
  <div
    id="peek-request-selector"
    class="float-right"
  >
    <select v-model="currentRequestId">
      <option
        v-for="request in requests"
        :key="request.id"
        :value="request.id"
      >
        {{ truncatedUrl(request.url) }}
      </option>
    </select>
  </div>
</template>
