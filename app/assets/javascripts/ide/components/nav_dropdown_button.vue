<script>
import { mapState } from 'vuex';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';
import Icon from '~/vue_shared/components/icon.vue';

const EMPTY_LABEL = '-';

export default {
  components: {
    Icon,
    DropdownButton,
  },
  props: {
    showMergeRequests: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    ...mapState(['currentBranchId', 'currentMergeRequestId']),
    mergeRequestLabel() {
      return this.currentMergeRequestId ? `!${this.currentMergeRequestId}` : EMPTY_LABEL;
    },
    branchLabel() {
      return this.currentBranchId || EMPTY_LABEL;
    },
  },
};
</script>

<template>
  <dropdown-button>
    <span class="row">
      <span class="col-auto text-truncate" :class="{ 'col-7': showMergeRequests }">
        <icon :size="16" :aria-label="__('Current Branch')" name="branch" /> {{ branchLabel }}
      </span>
      <span v-if="showMergeRequests" class="col-5 pl-0 text-truncate">
        <icon :size="16" :aria-label="__('Merge Request')" name="merge-request" />
        {{ mergeRequestLabel }}
      </span>
    </span>
  </dropdown-button>
</template>
