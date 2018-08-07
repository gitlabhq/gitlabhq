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
  computed: {
    ...mapState(['currentBranchId', 'currentMergeRequestId']),
    mergeRequestLabel() {
      return this.currentMergeRequestId
        ? `!${this.currentMergeRequestId}`
        : EMPTY_LABEL;
    },
    branchLabel() {
      return this.currentBranchId || EMPTY_LABEL;
    },
  },
};
</script>

<template>
  <dropdown-button>
    <span
      class="row"
    >
      <span
        class="col-7 text-truncate"
      >
        <icon
          :size="16"
          :aria-label="__('Current Branch')"
          name="branch"
        />
        {{ branchLabel }}
      </span>
      <span
        class="col-5 pl-0 text-truncate"
      >
        <icon
          :size="16"
          :aria-label="__('Merge Request')"
          name="merge-request"
        />
        {{ mergeRequestLabel }}
      </span>
    </span>
  </dropdown-button>
</template>
