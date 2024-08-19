<script>
import { GlAccordion, GlAccordionItem, GlSkeletonLoader, GlEmptyState } from '@gitlab/ui';
import EMPTY_DISCUSSION_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg';
import { isLoggedIn } from '~/lib/utils/common_utils';

import { s__, n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../constants';
import updateActiveDiscussionMutation from '../graphql/mutations/update_active_discussion.mutation.graphql';
import { extractDiscussions, extractParticipants } from '../utils/design_management_utils';
import DesignDiscussion from './design_notes/design_discussion.vue';
import DescriptionForm from './design_description/description_form.vue';
import DesignNoteSignedOut from './design_notes/design_note_signed_out.vue';

export default {
  components: {
    DesignDiscussion,
    DesignNoteSignedOut,
    GlAccordion,
    GlAccordionItem,
    GlSkeletonLoader,
    GlEmptyState,
    DescriptionForm,
    DesignDisclosure,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
    registerPath: {
      default: '',
    },
    signInPath: {
      default: '',
    },
  },
  props: {
    design: {
      type: Object,
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
  },
  data() {
    return {
      discussionWithOpenForm: '',
      isLoggedIn: isLoggedIn(),
      emptyDiscussionSvgPath: EMPTY_DISCUSSION_URL,
    };
  },
  computed: {
    discussions() {
      return extractDiscussions(this.design.discussions);
    },
    issue() {
      return {
        ...this.design.issue,
        webPath: this.design.issue?.webPath.substr(1),
      };
    },
    discussionParticipants() {
      return extractParticipants(this.issue.participants?.nodes || []);
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
    unresolvedDiscussions() {
      return this.discussions.filter((discussion) => !discussion.resolved);
    },
    unresolvedDiscussionsCount() {
      return n__('%d Thread', '%d Threads', this.unresolvedDiscussions.length);
    },
    isResolvedDiscussionsExpanded: {
      get() {
        return this.resolvedDiscussionsExpanded;
      },
      set(isExpanded) {
        this.$emit('toggleResolvedComments', isExpanded);
      },
    },
    showDescriptionForm() {
      // user either has permission to add or update description,
      // or the existing description should be shown read-only.
      return (
        !this.isLoading &&
        (this.design.issue?.userPermissions?.updateDesign || Boolean(this.design.descriptionHtml))
      );
    },
  },
  mounted() {
    if (!this.isResolvedCommentsPopoverHidden && this.$refs.resolvedComments) {
      this.$refs.resolvedComments.$el.scrollIntoView();
    }
  },
  methods: {
    handleSidebarClick() {
      this.updateActiveDiscussion();
    },
    updateActiveDiscussion(id) {
      this.$apollo.mutate({
        mutation: updateActiveDiscussionMutation,
        variables: {
          id,
          source: ACTIVE_DISCUSSION_SOURCE_TYPES.discussion,
        },
      });
    },
    closeCommentForm() {
      this.comment = '';
      this.$emit('closeCommentForm');
    },
    updateDiscussionWithOpenForm(id) {
      this.discussionWithOpenForm = id;
    },
  },
  i18n: {
    resolveCommentsToggleText: s__('DesignManagement|Resolved Comments'),
  },
};
</script>

<template>
  <design-disclosure :open="isOpen">
    <template #default>
      <div class="image-notes gl-h-full gl-pt-0" @click.self="handleSidebarClick">
        <description-form
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
            :svg-path="emptyDiscussionSvgPath"
          >
            <template #description>
              {{
                s__(`DesignManagement|Click on the image where you'd like to add a new comment.`)
              }}
            </template>
          </gl-empty-state>
          <design-note-signed-out
            v-if="!isLoggedIn"
            class="gl-mb-4"
            :register-path="registerPath"
            :sign-in-path="signInPath"
            :is-add-discussion="true"
          />
          <design-discussion
            v-for="discussion in unresolvedDiscussions"
            :key="discussion.id"
            :discussion="discussion"
            :design-id="$route.params.id"
            :noteable-id="design.id"
            :markdown-preview-path="markdownPreviewPath"
            :register-path="registerPath"
            :sign-in-path="signInPath"
            :resolved-discussions-expanded="resolvedDiscussionsExpanded"
            :discussion-with-open-form="discussionWithOpenForm"
            data-testid="unresolved-discussion"
            @create-note-error="$emit('onDesignDiscussionError', $event)"
            @update-note-error="$emit('updateNoteError', $event)"
            @delete-note-error="$emit('deleteNoteError', $event)"
            @resolve-discussion-error="$emit('resolveDiscussionError', $event)"
            @update-active-discussion="updateActiveDiscussion(discussion.notes[0].id)"
            @open-form="updateDiscussionWithOpenForm"
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
                :markdown-preview-path="markdownPreviewPath"
                :register-path="registerPath"
                :sign-in-path="signInPath"
                :resolved-discussions-expanded="resolvedDiscussionsExpanded"
                :discussion-with-open-form="discussionWithOpenForm"
                data-testid="resolved-discussion"
                @error="$emit('onDesignDiscussionError', $event)"
                @update-note-error="$emit('updateNoteError', $event)"
                @delete-note-error="$emit('deleteNoteError', $event)"
                @open-form="updateDiscussionWithOpenForm"
                @update-active-discussion="updateActiveDiscussion(discussion.notes[0].id)"
              />
            </gl-accordion-item>
          </gl-accordion>
          <slot name="reply-form"></slot>
        </template>
      </div>
    </template>
  </design-disclosure>
</template>
