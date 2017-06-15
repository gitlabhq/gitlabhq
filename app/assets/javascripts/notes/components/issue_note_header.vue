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
      required: false,
      default: '',
    },
    actionTextHtml: {
      type: String,
      required: false,
      default: '',
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
    toggleHandler: {
      type: Function,
      required: false,
    },
  },
  components: {
    TimeAgoTooltip,
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
        <template v-if="actionText">
          {{actionText}}
        </template>
        <span
          v-if="actionTextHtml"
          v-html="actionTextHtml"
          class="system-note-message"></span>
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
        @click="toggleHandler"
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
