<script>
import { mapGetters, createNamespacedHelpers } from 'vuex';

const {
  mapState: mapCommitState,
  mapGetters: mapCommitGetters,
  mapActions: mapCommitActions,
} = createNamespacedHelpers('commit');

export default {
  computed: {
    ...mapCommitState(['shouldCreateMR']),
    ...mapCommitGetters(['isCommittingToCurrentBranch', 'isCommittingToDefaultBranch']),
    ...mapGetters(['hasMergeRequest', 'isOnDefaultBranch']),
    currentBranchHasMr() {
      return this.hasMergeRequest && this.isCommittingToCurrentBranch;
    },
    showNewMrOption() {
      return (
        this.isCommittingToDefaultBranch || !this.currentBranchHasMr || this.isCommittingToNewBranch
      );
    },
  },
  mounted() {
    this.setShouldCreateMR();
  },
  methods: {
    ...mapCommitActions(['toggleShouldCreateMR', 'setShouldCreateMR']),
  },
};
</script>

<template>
  <div v-if="showNewMrOption">
    <hr class="my-2" />
    <label class="mb-0">
      <input :checked="shouldCreateMR" type="checkbox" @change="toggleShouldCreateMR" />
      <span class="prepend-left-10">
        {{ __('Start a new merge request') }}
      </span>
    </label>
  </div>
</template>
