<script>
import { GlPopover } from '@gitlab/ui';
import { glEmojiTag } from '~/emoji';
import { n__ } from '~/locale';

export default {
  components: {
    GlPopover,
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
  computed: {
    requestsWithWarnings() {
      return this.requests.filter(request => request.hasWarnings);
    },
    warningMessage() {
      return n__(
        '%d request with warnings',
        '%d requests with warnings',
        this.requestsWithWarnings.length,
      );
    },
  },
  watch: {
    currentRequestId(newRequestId) {
      this.$emit('change-current-request', newRequestId);
    },
  },
  methods: {
    glEmojiTag,
  },
};
</script>
<template>
  <div id="peek-request-selector">
    <select v-model="currentRequestId">
      <option
        v-for="request in requests"
        :key="request.id"
        :value="request.id"
        class="qa-performance-bar-request"
      >
        {{ request.truncatedUrl }}
        <span v-if="request.hasWarnings">(!)</span>
      </option>
    </select>
    <span v-if="requestsWithWarnings.length">
      <span id="performance-bar-request-selector-warning" v-html="glEmojiTag('warning')"></span>
      <gl-popover
        target="performance-bar-request-selector-warning"
        :content="warningMessage"
        triggers="hover focus"
      />
    </span>
  </div>
</template>
