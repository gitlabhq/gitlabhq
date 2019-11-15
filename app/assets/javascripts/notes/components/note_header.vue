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
      required: false,
      default: () => ({}),
    },
    createdAt: {
      type: String,
      required: false,
      default: null,
    },
    actionText: {
      type: String,
      required: false,
      default: '',
    },
    noteId: {
      type: [String, Number],
      required: false,
      default: null,
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
    hasAuthor() {
      return this.author && Object.keys(this.author).length;
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
    <div v-if="includeToggle" class="discussion-actions">
      <button
        class="note-action-button discussion-toggle-button js-vue-toggle-button"
        type="button"
        @click="handleToggle"
      >
        <i :class="toggleChevronClass" class="fa" aria-hidden="true"></i>
        {{ __('Toggle thread') }}
      </button>
    </div>
    <a
      v-if="hasAuthor"
      v-once
      :href="author.path"
      class="js-user-link"
      :data-user-id="author.id"
      :data-username="author.username"
    >
      <slot name="note-header-info"></slot>
      <span class="note-header-author-name bold">{{ author.name }}</span>
      <span v-if="author.status_tooltip_html" v-html="author.status_tooltip_html"></span>
      <span class="note-headline-light">@{{ author.username }}</span>
    </a>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="note-headline-light note-headline-meta">
      <span class="system-note-message"> <slot></slot> </span>
      <template v-if="createdAt">
        <span class="system-note-separator">
          <template v-if="actionText">{{ actionText }}</template>
        </span>
        <a
          :href="noteTimestampLink"
          class="note-timestamp system-note-separator"
          @click="updateTargetNoteHash"
        >
          <time-ago-tooltip :time="createdAt" tooltip-placement="bottom" />
        </a>
      </template>
      <slot name="extra-controls"></slot>
      <i
        class="fa fa-spinner fa-spin editing-spinner"
        :aria-label="__('Comment is being updated')"
        aria-hidden="true"
      ></i>
    </span>
  </div>
</template>
