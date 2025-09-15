<script>
import {
  GlTooltipDirective,
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import EmojiPicker from '~/emoji/components/picker.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { WIKI_CONTAINER_TYPE } from '~/wikis/constants';
import discussionToggleResolveMutation from '../graphql/discussion_toggle_resolve.mutation.graphql';

export default {
  i18n: {
    buttonText: __('Reply to comment'),
    editCommentLabel: __('Edit comment'),
    deleteCommentLabel: __('Delete comment'),
    moreActionsLabel: __('More actions'),
    reportAbuse: __('Report abuse'),
  },
  name: 'NoteActions',
  components: {
    UserAccessRoleBadge,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    AbuseCategorySelector,
    EmojiPicker,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['containerName', 'containerType', 'pageAuthorEmail'],
  props: {
    authorId: {
      type: String,
      required: true,
    },
    authorEmails: {
      type: Array,
      required: false,
      default: () => [],
    },
    showReply: {
      type: Boolean,
      required: false,
      default: false,
    },
    showEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReportAsAbuse: {
      type: Boolean,
      required: false,
      default: false,
    },
    noteUrl: {
      type: String,
      required: false,
      default: '',
    },
    accessLevel: {
      type: String,
      required: false,
      default: '',
    },
    canAwardEmoji: {
      type: Boolean,
      required: false,
      default: false,
    },
    canResolve: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolved: {
      type: Boolean,
      required: false,
      default: false,
    },
    discussionId: {
      type: String,
      required: false,
      default: '',
    },
    resolvedBy: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isReportAbuseDrawerOpen: false,
      loading: false,
    };
  },
  computed: {
    showActionsDropdown() {
      return true;
    },
    showMemberBadge() {
      return Boolean(this.accessLevel);
    },
    showAuthorBadge() {
      return this.authorEmails.includes(this.pageAuthorEmail);
    },
    displayMemberBadgeText() {
      return sprintf(
        this.containerType === WIKI_CONTAINER_TYPE.PROJECT
          ? __('This user has the %{access} role in the %{name} project.')
          : __('This user has the %{access} role in the %{name} group.'),
        {
          access: this.accessLevel.toLowerCase(),
          name: this.containerName,
        },
      );
    },
    resolveIcon() {
      if (!this.loading) {
        return this.isResolved ? 'check-circle-filled' : 'check-circle';
      }
      return null;
    },
    resolveButtonTitle() {
      let title = __('Resolve thread');

      if (this.resolvedBy) {
        title = sprintf(__('Resolved by %{name}'), { name: this.resolvedBy.name });
      }

      return title;
    },
  },
  methods: {
    toggleAbuseDrawer(val) {
      this.isReportAbuseDrawerOpen = val;
    },
    handleCopyLink() {
      this.$toast?.show(__('Link copied to clipboard.'));
    },
    async onResolve() {
      this.loading = true;
      try {
        await this.$apollo.mutate({
          mutation: discussionToggleResolveMutation,
          variables: {
            id: this.discussionId,
            resolve: !this.isResolved,
          },
        });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>
<template>
  <div class="note-actions">
    <user-access-role-badge
      v-if="showAuthorBadge"
      v-gl-tooltip
      data-testid="wiki-note-user-author-badge"
      class="gl-mr-3 gl-hidden @sm/panel:gl-block"
      :title="__('This user is the author of this page.')"
    >
      {{ __('Author') }}
    </user-access-role-badge>
    <user-access-role-badge
      v-if="showMemberBadge"
      v-gl-tooltip
      data-testid="wiki-note-user-access-role-badge"
      class="gl-mr-3 gl-hidden @sm/panel:gl-block"
      :title="displayMemberBadgeText"
    >
      {{ accessLevel }}
    </user-access-role-badge>
    <span class="note-actions__mobile-spacer"></span>
    <gl-button
      v-if="canResolve"
      ref="resolveButton"
      v-gl-tooltip
      data-testid="wiki-note-resolve-button"
      category="tertiary"
      class="note-action-button"
      :class="{ '!gl-text-success': isResolved }"
      :title="resolveButtonTitle"
      :aria-label="resolveButtonTitle"
      :icon="resolveIcon"
      :loading="loading"
      @click="onResolve"
    />
    <emoji-picker
      v-if="canAwardEmoji"
      data-testid="note-emoji-button"
      toggle-class="add-reaction-button btn-default-tertiary"
      :right="false"
      @click="(name) => $emit('award-emoji', name)"
    />
    <gl-button
      v-if="showReply"
      ref="replyButton"
      v-gl-tooltip
      class="js-reply-button"
      data-testid="wiki-note-reply-button"
      data-track-action="click_button"
      data-track-label="reply_comment_button"
      category="tertiary"
      icon="reply"
      :title="$options.i18n.buttonText"
      :aria-label="$options.i18n.buttonText"
      @click="$emit('reply')"
    />
    <gl-button
      v-if="showEdit"
      v-gl-tooltip
      :title="$options.i18n.editCommentLabel"
      :aria-label="$options.i18n.editCommentLabel"
      icon="pencil"
      category="tertiary"
      class="note-action-button js-note-edit"
      data-testid="wiki-note-edit-button"
      @click="$emit('edit')"
    />
    <div v-if="showActionsDropdown" class="more-actions dropdown">
      <gl-disclosure-dropdown
        v-gl-tooltip
        :title="$options.i18n.moreActionsLabel"
        :toggle-text="$options.i18n.moreActionsLabel"
        data-testid="wiki-note-more-actions"
        text-sr-only
        icon="ellipsis_v"
        category="tertiary"
        placement="bottom-end"
        class="note-action-button more-actions-toggle print:gl-hidden"
        no-caret
      >
        <gl-disclosure-dropdown-item
          v-if="noteUrl"
          class="js-btn-copy-note-link"
          data-testid="wiki-note-copy-note"
          :data-clipboard-text="noteUrl"
          @action="handleCopyLink()"
        >
          <template #list-item>
            {{ __('Copy link') }}
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-group v-if="canReportAsAbuse || showEdit" bordered>
          <gl-disclosure-dropdown-item
            v-if="canReportAsAbuse"
            data-testid="wiki-note-report-abuse-button"
            @action="toggleAbuseDrawer(true)"
          >
            <template #list-item>
              {{ $options.i18n.reportAbuse }}
            </template>
          </gl-disclosure-dropdown-item>
          <gl-disclosure-dropdown-item
            v-if="showEdit"
            data-testid="wiki-note-delete-button"
            class="js-note-delete"
            @action="$emit('delete')"
          >
            <template #list-item>
              <span class="gl-text-danger">{{ __('Delete comment') }}</span>
            </template>
          </gl-disclosure-dropdown-item>
        </gl-disclosure-dropdown-group>
      </gl-disclosure-dropdown>
    </div>

    <abuse-category-selector
      v-if="canReportAsAbuse && isReportAbuseDrawerOpen"
      :reported-user-id="parseInt(authorId)"
      :reported-from-url="noteUrl"
      :show-drawer="isReportAbuseDrawerOpen"
      @close-drawer="toggleAbuseDrawer(false)"
    />
  </div>
</template>
