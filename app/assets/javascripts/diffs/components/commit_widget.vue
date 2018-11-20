<script>
import CommitItem from './commit_item.vue';

/**
 * CommitWidget
 *
 * -----------------------------------------------------------------
 * WARNING: Please keep changes up-to-date with the following files:
 * - `views/projects/merge_requests/diffs/_commit_widget.html.haml`
 * -----------------------------------------------------------------
 *
 * This Component was cloned from a HAML view. For the time being,
 * they coexist, but there is an issue to remove the duplication.
 * https://gitlab.com/gitlab-org/gitlab-ce/issues/51613
 *
 */
export default {
  components: {
    CommitItem,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="info-well w-100">
    <div class="well-segment">
      <ul class="blob-commit-info">
        <commit-item :commit="commit" />
      </ul>
    </div>
  </div>
</template>
