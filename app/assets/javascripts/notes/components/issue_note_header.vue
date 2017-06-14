<script>
import TimeAgoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';

export default {
  props: {
    author: {
      type: Object,
      required: true,
    },
    createdAt: {
      type: String,
      required: true,
    },
    actionText: {
      type: String,
      required: true,
    },
    notePath: {
      type: String,
      required: true,
    },
    includeToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    discussionId: {
      type: String,
      required: false,
    },
  },
  components: {
    TimeAgoTooltip,
  },
  methods: {
    doShit() {
      this.$store.commit('toggleDiscussion', {
        discussionId: this.discussionId,
      });
    },
  },
};
</script>

<template>
  <div class="note-header-info">
    <a :href="author.path">
      <span class="note-header-author-name">
        {{author.name}}
      </span>
      <span class="note-headline-light">
        @{{author.username}}
      </span>
    </a>
    <span class="note-headline-light">
      <span class="note-headline-meta">
        {{actionText}}
        <a :href="notePath">
          <time-ago-tooltip
            :time="createdAt"
            tooltipPlacement="bottom" />
        </a>
      </span>
    </span>
    <div
      v-if="includeToggle"
      class="discussion-actions">
      <button
        @click="doShit"
        class="note-action-button discussion-toggle-button js-toggle-button"
        type="button">
          <i
            aria-hidden="true"
            class="fa fa-chevron-up"></i>
          Toggle discussion
      </button>
    </div>
  </div>
</template>
