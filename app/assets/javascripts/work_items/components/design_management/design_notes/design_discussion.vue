<script>
import { GlButton, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import highlightCurrentUser from '~/behaviors/markdown/highlight_current_user';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import activeDiscussionQuery from '../graphql/client/active_design_discussion.query.graphql';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../constants';
import DesignNote from './design_note.vue';
import ToggleRepliesWidget from './toggle_replies_widget.vue';

export default {
  components: {
    DesignNote,
    DesignNotePin,
    GlButton,
    GlLink,
    TimeAgoTooltip,
    ToggleRepliesWidget,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  apollo: {
    activeDesignDiscussion: {
      query: activeDiscussionQuery,
      result({ data }) {
        if (this.discussion.resolved && !this.resolvedDiscussionsExpanded) {
          return;
        }

        this.$nextTick(() => {
          // We watch any changes to the active discussion from the design pins and scroll to this discussion if it exists.
          // We don't want scrollIntoView to be triggered from the discussion click itself.
          if (this.$el && this.shouldScrollToDiscussion(data.activeDesignDiscussion)) {
            this.$el.scrollIntoView({
              behavior: 'smooth',
              inline: 'start',
            });
          }
        });
      },
    },
  },
  data() {
    return {
      areRepliesCollapsed: this.discussion.resolved,
      isLoggedIn: isLoggedIn(),
      activeDesignDiscussion: {},
    };
  },
  computed: {
    resolveCheckboxText() {
      return this.discussion.resolved
        ? s__('DesignManagement|Unresolve thread')
        : s__('DesignManagement|Resolve thread');
    },
    firstNote() {
      return this.discussion.notes[0];
    },
    discussionReplies() {
      return this.discussion.notes.slice(1);
    },
    areRepliesShown() {
      return !this.areRepliesCollapsed;
    },
    resolveIconName() {
      return this.discussion.resolved ? 'check-circle-filled' : 'check-circle';
    },
    isRepliesWidgetVisible() {
      return this.discussionReplies.length > 0;
    },
    isDiscussionActive() {
      return this.discussion.notes.some(({ id }) => id === this.activeDesignDiscussion.id);
    },
  },
  mounted() {
    this.$nextTick(() => {
      highlightCurrentUser(this.$el.querySelectorAll('.gfm-project_member'));
    });
  },
  updated() {
    this.$nextTick(() => {
      highlightCurrentUser(this.$el.querySelectorAll('.gfm-project_member'));
    });
  },
  methods: {
    shouldScrollToDiscussion(activeDesignDiscussion) {
      const ALLOWED_ACTIVE_DISCUSSION_SOURCES = [
        ACTIVE_DISCUSSION_SOURCE_TYPES.pin,
        ACTIVE_DISCUSSION_SOURCE_TYPES.url,
      ];
      const { source } = activeDesignDiscussion;
      return ALLOWED_ACTIVE_DISCUSSION_SOURCES.includes(source) && this.isDiscussionActive;
    },
  },
};
</script>

<template>
  <div class="design-discussion-wrapper" @click="$emit('update-active-discussion')">
    <design-note-pin :is-resolved="discussion.resolved" :label="discussion.index" />
    <ul
      class="design-discussion bordered-box gl-relative gl-list-none gl-p-0"
      :class="{ 'gl-bg-blue-50': isDiscussionActive }"
      data-testid="design-discussion-content"
    >
      <design-note :note="firstNote">
        <template v-if="isLoggedIn && discussion.resolvable" #resolve-discussion>
          <gl-button
            v-gl-tooltip
            :aria-label="resolveCheckboxText"
            :icon="resolveIconName"
            :title="resolveCheckboxText"
            :disabled="true"
            category="tertiary"
            data-testid="resolve-button"
          />
        </template>
        <template v-if="discussion.resolved" #resolved-status>
          <p class="gl-m-0 gl-mt-5 gl-text-sm gl-text-gray-500" data-testid="resolved-message">
            {{ __('Resolved by') }}
            <gl-link
              class="link-inherit-color gl-text-sm gl-text-gray-500 gl-no-underline"
              :href="discussion.resolvedBy.webUrl"
              target="_blank"
              >{{ discussion.resolvedBy.name }}</gl-link
            >
            <time-ago-tooltip :time="discussion.resolvedAt" tooltip-placement="bottom" />
          </p>
        </template>
      </design-note>
      <toggle-replies-widget
        v-if="isRepliesWidgetVisible"
        :collapsed="areRepliesCollapsed"
        :replies="discussionReplies"
        @toggle="areRepliesCollapsed = !areRepliesCollapsed"
      />
      <design-note
        v-for="note in discussionReplies"
        v-show="areRepliesShown"
        :key="note.id"
        :note="note"
      />
    </ul>
  </div>
</template>
