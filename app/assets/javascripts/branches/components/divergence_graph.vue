<script>
import { sprintf, __ } from '~/locale';
import { MAX_COMMIT_COUNT } from '../constants';
import GraphBar from './graph_bar.vue';

export default {
  components: {
    GraphBar,
  },
  props: {
    defaultBranch: {
      type: String,
      required: true,
    },
    distance: {
      type: Number,
      required: false,
      default: null,
    },
    aheadCount: {
      type: Number,
      required: true,
    },
    behindCount: {
      type: Number,
      required: true,
    },
    maxCommits: {
      type: Number,
      required: true,
    },
  },
  computed: {
    title() {
      if (this.distance) {
        return sprintf(
          __('More than %{number_commits_distance} commits different with %{default_branch}'),
          {
            number_commits_distance:
              this.distance >= MAX_COMMIT_COUNT ? `${MAX_COMMIT_COUNT - 1}+` : this.distance,
            default_branch: this.defaultBranch,
          },
        );
      }

      return sprintf(
        __(
          '%{number_commits_behind} commits behind %{default_branch}, %{number_commits_ahead} commits ahead',
        ),
        {
          number_commits_behind: this.behindCount,
          number_commits_ahead: this.aheadCount,
          default_branch: this.defaultBranch,
        },
      );
    },
  },
};
</script>

<template>
  <div :title="title" class="divergence-graph px-2 gl-hidden md:gl-block">
    <template v-if="distance">
      <graph-bar :count="distance" :max-commits="maxCommits" position="full" />
    </template>
    <template v-else>
      <graph-bar :count="behindCount" :max-commits="maxCommits" position="left" />
      <div class="graph-separator float-left mt-1"></div>
      <graph-bar :count="aheadCount" :max-commits="maxCommits" position="right" />
    </template>
  </div>
</template>
