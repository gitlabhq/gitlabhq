<script>
import { GlButton, GlLink, GlLoadingIcon, GlSprintf, GlIcon } from '@gitlab/ui';
import { isExperimentVariant } from '~/experimentation/utils';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { INVITE_MEMBERS_IN_COMMENT } from '~/invite_members/constants';

export default {
  inviteMembersInComment: INVITE_MEMBERS_IN_COMMENT,
  components: {
    GlButton,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlIcon,
    InviteMembersTrigger,
  },
  props: {
    markdownDocsPath: {
      type: String,
      required: true,
    },
    quickActionsDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    canAttachFile: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    hasQuickActionsDocsPath() {
      return this.quickActionsDocsPath !== '';
    },
    inviteCommentEnabled() {
      return isExperimentVariant(INVITE_MEMBERS_IN_COMMENT, 'invite_member_link');
    },
  },
};
</script>

<template>
  <div class="comment-toolbar clearfix">
    <div class="toolbar-text">
      <template v-if="!hasQuickActionsDocsPath && markdownDocsPath">
        <gl-link :href="markdownDocsPath" target="_blank">
          {{ __('Markdown is supported') }}
        </gl-link>
      </template>
      <template v-if="hasQuickActionsDocsPath && markdownDocsPath">
        <gl-sprintf
          :message="
            __(
              '%{markdownDocsLinkStart}Markdown%{markdownDocsLinkEnd} and %{quickActionsDocsLinkStart}quick actions%{quickActionsDocsLinkEnd} are supported',
            )
          "
        >
          <template #markdownDocsLink="{ content }">
            <gl-link :href="markdownDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
          <template #quickActionsDocsLink="{ content }">
            <gl-link :href="quickActionsDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </div>
    <span v-if="canAttachFile" class="uploading-container">
      <invite-members-trigger
        v-if="inviteCommentEnabled"
        classes="gl-mr-3 gl-vertical-align-text-bottom"
        :display-text="s__('InviteMember|Invite Member')"
        icon="assignee"
        variant="link"
        :track-experiment="$options.inviteMembersInComment"
        :trigger-source="$options.inviteMembersInComment"
        data-track-event="comment_invite_click"
      />
      <span class="uploading-progress-container hide">
        <gl-icon name="media" />
        <span class="attaching-file-message"></span>
        <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
        <span class="uploading-progress">0%</span>
        <gl-loading-icon size="sm" inline />
      </span>
      <span class="uploading-error-container hide">
        <span class="uploading-error-icon">
          <gl-icon name="media" />
        </span>
        <span class="uploading-error-message"></span>

        <gl-sprintf
          :message="
            __(
              '%{retryButtonStart}Try again%{retryButtonEnd} or %{newFileButtonStart}attach a new file%{newFileButtonEnd}.',
            )
          "
        >
          <template #retryButton="{ content }">
            <gl-button
              variant="link"
              category="primary"
              class="retry-uploading-link gl-vertical-align-baseline"
            >
              {{ content }}
            </gl-button>
          </template>
          <template #newFileButton="{ content }">
            <gl-button
              variant="link"
              category="primary"
              class="markdown-selector attach-new-file gl-vertical-align-baseline"
            >
              {{ content }}
            </gl-button>
          </template>
        </gl-sprintf>
      </span>
      <gl-button
        icon="media"
        variant="link"
        category="primary"
        class="markdown-selector button-attach-file gl-vertical-align-text-bottom"
      >
        {{ __('Attach a file') }}
      </gl-button>
      <gl-button
        variant="link"
        category="primary"
        class="button-cancel-uploading-files gl-vertical-align-baseline hide"
      >
        {{ __('Cancel') }}
      </gl-button>
    </span>
  </div>
</template>
