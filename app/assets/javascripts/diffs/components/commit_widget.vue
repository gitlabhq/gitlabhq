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
 * https://gitlab.com/gitlab-org/gitlab-foss/issues/51613
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
    collapsible: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div class="info-well mw-100 mx-0">
    <div class="well-segment">
      <ul class="blob-commit-info">
        <commit-item :commit="commit" :collapsible="collapsible" />
      </ul>
    </div>
  </div>
</template>
