<script>
import {
  GlTooltipDirective,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
} from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import { throttle } from 'lodash';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import discussionNavigation from '../mixins/discussion_navigation';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
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
    ]),
    allResolved() {
      return this.unresolvedDiscussionsCount === 0;
    },
    allExpanded() {
      return this.allResolvableDiscussions.every((discussion) => discussion.expanded);
    },
    toggleThreadsLabel() {
      return this.allExpanded ? __('Collapse all threads') : __('Expand all threads');
    },
    resolveAllDiscussionsIssuePath() {
      return this.getNoteableData.create_issue_to_resolve_discussions_path;
    },
  },
  methods: {
    ...mapActions(['setExpandDiscussions']),
    handleExpandDiscussions() {
      this.setExpandDiscussions({
        discussionIds: this.allResolvableDiscussions.map((discussion) => discussion.id),
        expanded: !this.allExpanded,
      });
    },
  },
};
</script>

<template>
  <div
    v-if="resolvableDiscussionsCount > 0"
    id="discussionCounter"
    ref="discussionCounter"
    class="gl-display-flex discussions-counter"
  >
    <div
      class="gl-display-flex gl-align-items-center gl-pl-4 gl-rounded-base gl-mr-3 gl-min-h-7"
      :class="{
        'gl-bg-orange-50': blocksMerge && !allResolved,
        'gl-bg-gray-50': !blocksMerge || allResolved,
      }"
      data-testid="discussions-counter-text"
    >
      <template v-if="allResolved">
        {{ __('All threads resolved!') }}
        <gl-dropdown
          v-gl-tooltip:discussionCounter.hover.bottom
          size="small"
          category="tertiary"
          right
          :title="__('Thread options')"
          :aria-label="__('Thread options')"
          toggle-class="btn-icon"
          class="gl-pt-0! gl-px-2 gl-h-full gl-ml-2"
        >
          <template #button-content>
            <gl-icon name="ellipsis_v" class="mr-0" />
          </template>
          <gl-dropdown-item
            data-testid="toggle-all-discussions-btn"
            @click="handleExpandDiscussions"
          >
            {{ toggleThreadsLabel }}
          </gl-dropdown-item>
        </gl-dropdown>
      </template>
      <template v-else>
        {{ n__('%d unresolved thread', '%d unresolved threads', unresolvedDiscussionsCount) }}
        <gl-button-group class="gl-ml-3">
          <gl-button
            v-gl-tooltip:discussionCounter.hover.bottom
            :title="__('Go to previous unresolved thread')"
            :aria-label="__('Go to previous unresolved thread')"
            class="discussion-previous-btn gl-rounded-base! gl-px-2!"
            data-track-action="click_button"
            data-track-label="mr_previous_unresolved_thread"
            data-track-property="click_previous_unresolved_thread_top"
            icon="chevron-lg-up"
            category="tertiary"
            @click="jumpPrevious"
          />
          <gl-button
            v-gl-tooltip:discussionCounter.hover.bottom
            :title="__('Go to next unresolved thread')"
            :aria-label="__('Go to next unresolved thread')"
            class="discussion-next-btn gl-rounded-base! gl-px-2!"
            data-track-action="click_button"
            data-track-label="mr_next_unresolved_thread"
            data-track-property="click_next_unresolved_thread_top"
            icon="chevron-lg-down"
            category="tertiary"
            @click="jumpNext"
          />
          <gl-dropdown
            v-gl-tooltip:discussionCounter.hover.bottom
            size="small"
            category="tertiary"
            right
            :title="__('Thread options')"
            :aria-label="__('Thread options')"
            toggle-class="btn-icon"
            class="gl-pt-0! gl-px-2"
          >
            <template #button-content>
              <gl-icon name="ellipsis_v" class="mr-0" />
            </template>
            <gl-dropdown-item
              data-testid="toggle-all-discussions-btn"
              @click="handleExpandDiscussions"
            >
              {{ toggleThreadsLabel }}
            </gl-dropdown-item>
            <gl-dropdown-item
              v-if="resolveAllDiscussionsIssuePath && !allResolved"
              :href="resolveAllDiscussionsIssuePath"
            >
              {{ __('Resolve all with new issue') }}
            </gl-dropdown-item>
          </gl-dropdown>
        </gl-button-group>
      </template>
    </div>
  </div>
</template>
