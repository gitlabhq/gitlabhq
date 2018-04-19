<script>
import { mapActions } from 'vuex';
import timeAgoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    timeAgoTooltip,
  },
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
    noteId: {
      type: Number,
      required: true,
    },
    includeToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    toggleChevronClass() {
      return this.expanded ? 'fa-chevron-up' : 'fa-chevron-down';
    },
    noteTimestampLink() {
      return `#note_${this.noteId}`;
    },
  },
  methods: {
    ...mapActions(['setTargetNoteHash']),
    handleToggle() {
      this.$emit('toggleHandler');
    },
    updateTargetNoteHash() {
      this.setTargetNoteHash(this.noteTimestampLink);
    },
  },
};
</script>

<template>
  <div class="note-header-info">
    <div
      v-if="includeToggle"
      class="discussion-actions">
      <button
        @click="handleToggle"
        class="note-action-button discussion-toggle-button js-vue-toggle-button"
        type="button">
        <i
          :class="toggleChevronClass"
          class="fa"
          aria-hidden="true">
        </i>
        Toggle discussion
      </button>
    </div>
    <a :href="author.path">
      <span class="note-header-author-name">{{ author.name }}</span>
      <span class="note-headline-light">
        @{{ author.username }}
      </span>
    </a>
    <span class="note-headline-light">
      <span class="note-headline-meta">
        <template v-if="actionText">
          {{ actionText }}
        </template>
        <span
          v-if="actionTextHtml"
          v-html="actionTextHtml"
          class="system-note-message">
        </span>
        <a
          :href="noteTimestampLink"
          @click="updateTargetNoteHash"
          class="note-timestamp">
          <time-ago-tooltip
            :time="createdAt"
            tooltip-placement="bottom"
          />
        </a>
        <i
          class="fa fa-spinner fa-spin editing-spinner"
          aria-label="Comment is being updated"
          aria-hidden="true"
        >
        </i>
      </span>
    </span>
  </div>
</template>
