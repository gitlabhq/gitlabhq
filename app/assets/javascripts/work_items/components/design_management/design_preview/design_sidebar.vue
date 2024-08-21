<script>
import { GlAccordion, GlAccordionItem, GlSkeletonLoader, GlEmptyState } from '@gitlab/ui';
import EMPTY_DISCUSSION_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { s__, n__ } from '~/locale';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';
import { extractDiscussions } from '../utils';
import DesignDiscussion from '../design_notes/design_discussion.vue';
import DesignDescription from './design_description.vue';

export default {
  components: {
    DesignDescription,
    DesignDisclosure,
    DesignDiscussion,
    GlAccordion,
    GlAccordionItem,
    GlSkeletonLoader,
    GlEmptyState,
  },
  props: {
    design: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    isOpen: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
      resolvedDiscussionsExpanded: false,
    };
  },
  computed: {
    showDescription() {
      return !this.isLoading && Boolean(this.design.descriptionHtml);
    },
    discussions() {
      return this.design?.discussions ? extractDiscussions(this.design.discussions) : [];
    },
    unresolvedDiscussions() {
      return this.discussions.filter((discussion) => !discussion.resolved);
    },
    unresolvedDiscussionsCount() {
      return n__('%d Thread', '%d Threads', this.unresolvedDiscussions.length);
    },
    resolvedDiscussions() {
      return this.discussions.filter((discussion) => discussion.resolved);
    },
    hasResolvedDiscussions() {
      return this.resolvedDiscussions.length > 0;
    },
    resolvedDiscussionsTitle() {
      return `${this.$options.i18n.resolveCommentsToggleText} (${this.resolvedDiscussions.length})`;
    },
  },
  i18n: {
    resolveCommentsToggleText: s__('DesignManagement|Resolved Comments'),
  },
  EMPTY_DISCUSSION_URL,
};
</script>

<template>
  <design-disclosure :open="isOpen">
    <template #default>
      <div class="image-notes gl-h-full gl-pt-0">
        <design-description v-if="showDescription" :design="design" class="gl-border-b gl-my-5" />
        <div v-if="isLoading" class="gl-my-5">
          <gl-skeleton-loader />
        </div>
        <template v-else>
          <h3 data-testid="unresolved-discussion-count" class="gl-my-5 gl-text-lg !gl-leading-20">
            {{ unresolvedDiscussionsCount }}
          </h3>
          <gl-empty-state
            v-if="isLoggedIn && unresolvedDiscussions.length === 0"
            data-testid="new-discussion-disclaimer"
            :svg-path="$options.EMPTY_DISCUSSION_URL"
          />
          <design-discussion
            v-for="discussion in unresolvedDiscussions"
            :key="discussion.id"
            :discussion="discussion"
            :design-id="$route.params.id"
            :noteable-id="design.id"
            data-testid="unresolved-discussion"
          />
          <gl-accordion v-if="hasResolvedDiscussions" :header-level="3" class="gl-mb-5">
            <gl-accordion-item
              v-model="resolvedDiscussionsExpanded"
              :title="resolvedDiscussionsTitle"
              header-class="!gl-mb-5"
            >
              <design-discussion
                v-for="discussion in resolvedDiscussions"
                :key="discussion.id"
                :discussion="discussion"
                :design-id="$route.params.id"
                :noteable-id="design.id"
                :resolved-discussions-expanded="resolvedDiscussionsExpanded"
                data-testid="resolved-discussion"
              />
            </gl-accordion-item>
          </gl-accordion>
          <slot name="reply-form"></slot>
        </template>
      </div>
    </template>
  </design-disclosure>
</template>
