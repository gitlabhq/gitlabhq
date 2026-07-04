<script>
import { s__ } from '~/locale';
import MergeChecksMessage from './message.vue';

export default {
  name: 'MergeChecksCodeOwners',
  components: {
    MergeChecksMessage,
  },
  props: {
    check: {
      type: Object,
      required: true,
    },
  },
  computed: {
    missingOwners() {
      return this.check.missingOwners || [];
    },
    hasMissingOwners() {
      return this.missingOwners.length > 0;
    },
    missingOwnersSummary() {
      return s__('mrWidget|Waiting for approval from: %{owners}').replace(
        '%{owners}',
        this.missingOwners.join(', '),
      );
    },
  },
};
</script>

<template>
  <merge-checks-message :check="check">
    <template v-if="hasMissingOwners" #reason-footer>
      <p class="gl-mt-2 gl-mb-0 gl-text-sm gl-text-secondary" data-testid="missing-owners">
        {{ missingOwnersSummary }}
      </p>
    </template>
  </merge-checks-message>
</template>
