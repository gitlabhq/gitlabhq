<script>
import { GlAccordion, GlAccordionItem, GlSkeletonLoader, GlEmptyState } from '@gitlab/ui';
import EMPTY_DISCUSSION_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { s__, n__ } from '~/locale';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../constants';
import { extractDiscussions } from '../utils';
import updateActiveDiscussionMutation from '../graphql/client/update_active_design_discussion.mutation.graphql';
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
    designVariables: {
      type: Object,
      required: true,
    },
    isOpen: {
      type: Boolean,
      required: true,
    },
    resolvedDiscussionsExpanded: {
      type: Boolean,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    showDescriptionForm() {
      // user either has permission to add or update description,
      // or the existing description should be shown read-only.
      return (
        !this.isLoading &&
        (this.design.issue?.userPermissions?.updateDesign || Boolean(this.design.descriptionHtml))
      );
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
    isResolvedDiscussionsExpanded: {
      get() {
        return this.resolvedDiscussionsExpanded;
      },
      set(isExpanded) {
        this.$emit('toggleResolvedComments', isExpanded);
      },
    },
  },
  methods: {
    handleSidebarClick() {
      this.updateActiveDesignDiscussion();
    },
    updateActiveDesignDiscussion(id) {
      this.$apollo.mutate({
        mutation: updateActiveDiscussionMutation,
        variables: {
          id,
          source: ACTIVE_DISCUSSION_SOURCE_TYPES.discussion,
        },
      });
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
      <div class="image-notes gl-h-full gl-pt-0" @click.self="handleSidebarClick">
        <design-description
          v-if="showDescriptionForm"
          :design="design"
          :design-variables="designVariables"
          :markdown-preview-path="markdownPreviewPath"
          class="gl-border-b gl-my-5"
        />
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
            @update-active-discussion="updateActiveDesignDiscussion(discussion.notes[0].id)"
          />
          <gl-accordion v-if="hasResolvedDiscussions" :header-level="3" class="gl-mb-5">
            <gl-accordion-item
              v-model="isResolvedDiscussionsExpanded"
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
                @update-active-discussion="updateActiveDesignDiscussion(discussion.notes[0].id)"
              />
            </gl-accordion-item>
          </gl-accordion>
          <slot name="reply-form"></slot>
        </template>
      </div>
    </template>
  </design-disclosure>
</template>
