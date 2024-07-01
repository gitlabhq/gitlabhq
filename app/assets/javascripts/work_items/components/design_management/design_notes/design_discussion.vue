<script>
import { GlButton, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
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
  data() {
    return {
      areRepliesCollapsed: this.discussion.resolved,
      isLoggedIn: isLoggedIn(),
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
  },
};
</script>

<template>
  <div class="design-discussion-wrapper" @click="$emit('update-active-discussion')">
    <design-note-pin :is-resolved="discussion.resolved" :label="discussion.index" />
    <ul class="design-discussion bordered-box gl-relative gl-p-0 gl-list-none">
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
          <p class="gl-text-gray-500 gl-text-sm gl-m-0 gl-mt-5" data-testid="resolved-message">
            {{ __('Resolved by') }}
            <gl-link
              class="gl-text-gray-500 gl-no-underline gl-text-sm link-inherit-color"
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
