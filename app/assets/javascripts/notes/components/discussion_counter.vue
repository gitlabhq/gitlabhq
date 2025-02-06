<script>
import { GlButton, GlButtonGroup, GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import { throttle } from 'lodash';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  keysFor,
  MR_NEXT_UNRESOLVED_DISCUSSION,
  MR_PREVIOUS_UNRESOLVED_DISCUSSION,
} from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { sanitize } from '~/lib/dompurify';
import discussionNavigation from '../mixins/discussion_navigation';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDisclosureDropdown,
    GlButton,
    GlButtonGroup,
  },
  mixins: [glFeatureFlagsMixin(), discussionNavigation],
  props: {
    blocksMerge: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      jumpNext: throttle(this.jumpToNextDiscussion, 500),
      jumpPrevious: throttle(this.jumpToPreviousDiscussion, 500),
    };
  },
  computed: {
    ...mapGetters([
      'getNoteableData',
      'resolvableDiscussionsCount',
      'unresolvedDiscussionsCount',
      'allResolvableDiscussions',
      'allVisibleDiscussionsExpanded',
    ]),
    allResolved() {
      return this.unresolvedDiscussionsCount === 0;
    },
    toggleThreadsLabel() {
      return !this.allVisibleDiscussionsExpanded
        ? __('Show all comments')
        : __('Hide all comments');
    },
    nextUnresolvedDiscussionShortcutKey() {
      return shouldDisableShortcuts() ? null : keysFor(MR_NEXT_UNRESOLVED_DISCUSSION)[0];
    },
    nextUnresolvedDiscussionTitle() {
      return MR_NEXT_UNRESOLVED_DISCUSSION.description;
    },
    nextUnresolvedDiscussionTooltip() {
      const description = this.nextUnresolvedDiscussionTitle;
      const key = this.nextUnresolvedDiscussionShortcutKey;
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    previousUnresolvedDiscussionShortcutKey() {
      return shouldDisableShortcuts() ? null : keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION)[0];
    },
    previousUnresolvedDiscussionTitle() {
      return MR_PREVIOUS_UNRESOLVED_DISCUSSION.description;
    },
    previousUnresolvedDiscussionTooltip() {
      const description = this.previousUnresolvedDiscussionTitle;
      const key = this.previousUnresolvedDiscussionShortcutKey;
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    resolveAllDiscussionsIssuePath() {
      return this.getNoteableData.create_issue_to_resolve_discussions_path;
    },
    threadOptions() {
      const options = [
        {
          text: this.toggleThreadsLabel,
          action: this.toggleAllVisibleDiscussions,
          extraAttrs: {
            'data-testid': 'toggle-all-discussions-btn',
          },
        },
      ];

      if (this.resolveAllDiscussionsIssuePath && !this.allResolved) {
        options.push({
          text: __('Resolve all with new issue'),
          href: this.resolveAllDiscussionsIssuePath,
          extraAttrs: {
            'data-testid': 'resolve-all-with-issue-link',
          },
        });
      }

      return options;
    },
    isNotificationsTodosButtons() {
      return this.glFeatures.notificationsTodosButtons;
    },
  },
  methods: {
    ...mapActions(['toggleAllVisibleDiscussions']),
  },
};
</script>

<template>
  <div
    v-if="resolvableDiscussionsCount > 0"
    id="discussionCounter"
    ref="discussionCounter"
    class="discussions-counter gl-flex"
  >
    <div
      class="gl-flex gl-min-h-7 gl-items-center gl-rounded-base gl-pl-4"
      :class="{
        'gl-bg-orange-50': blocksMerge && !allResolved,
        'gl-bg-strong': !blocksMerge || allResolved,
        'gl-mr-3': !isNotificationsTodosButtons,
        'gl-mr-5': isNotificationsTodosButtons,
      }"
      data-testid="discussions-counter-text"
    >
      <template v-if="allResolved">
        {{ __('All threads resolved!') }}
        <gl-disclosure-dropdown
          v-gl-tooltip
          icon="ellipsis_v"
          size="small"
          category="tertiary"
          placement="bottom-end"
          no-caret
          :title="__('Thread options')"
          :aria-label="__('Thread options')"
          toggle-class="btn-icon"
          class="gl-ml-3 gl-h-full !gl-rounded-base !gl-pt-0"
          :items="threadOptions"
        />
      </template>
      <template v-else>
        {{ n__('%d unresolved thread', '%d unresolved threads', unresolvedDiscussionsCount) }}
        <gl-button-group class="gl-ml-3">
          <gl-button
            v-gl-tooltip.html="previousUnresolvedDiscussionTooltip"
            :aria-label="previousUnresolvedDiscussionTitle"
            :aria-keyshortcuts="previousUnresolvedDiscussionShortcutKey"
            class="discussion-previous-btn !gl-rounded-base !gl-px-2"
            data-track-action="click_button"
            data-track-label="mr_previous_unresolved_thread"
            data-track-property="click_previous_unresolved_thread_top"
            icon="chevron-lg-up"
            category="tertiary"
            @click="jumpPrevious"
          />
          <gl-button
            v-gl-tooltip.html="nextUnresolvedDiscussionTooltip"
            :aria-label="nextUnresolvedDiscussionTitle"
            :aria-keyshortcuts="nextUnresolvedDiscussionShortcutKey"
            class="discussion-next-btn !gl-rounded-base !gl-px-2"
            data-track-action="click_button"
            data-track-label="mr_next_unresolved_thread"
            data-track-property="click_next_unresolved_thread_top"
            icon="chevron-lg-down"
            category="tertiary"
            @click="jumpNext"
          />
          <gl-disclosure-dropdown
            v-gl-tooltip
            icon="ellipsis_v"
            size="small"
            category="tertiary"
            placement="bottom-end"
            no-caret
            :title="__('Thread options')"
            :aria-label="__('Thread options')"
            toggle-class="btn-icon"
            class="!gl-rounded-base !gl-pt-0"
            :items="threadOptions"
          />
        </gl-button-group>
      </template>
    </div>
  </div>
</template>
