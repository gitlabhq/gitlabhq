<script>
import {
  GlTooltipDirective,
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import * as constants from '~/notes/constants';

export default {
  name: 'NoteActions',
  i18n: {
    editCommentLabel: __('Edit comment'),
    deleteCommentLabel: __('Delete comment'),
    moreActionsLabel: __('More actions'),
    reportAbuse: __('Report abuse'),
  },
  components: {
    AbuseCategorySelector,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    ReplyButton,
    UserAccessRoleBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    authorId: {
      type: Number,
      required: true,
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
    isAuthor: {
      type: Boolean,
      required: false,
      default: false,
    },
    isContributor: {
      type: Boolean,
      required: false,
      default: false,
    },
    noteableType: {
      type: String,
      required: false,
      default: '',
    },
    projectName: {
      type: String,
      required: false,
      default: '',
    },
    showReply: {
      type: Boolean,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    canAwardEmoji: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReportAsAbuse: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      abuseDrawerOpen: false,
    };
  },
  computed: {
    shouldShowActionsDropdown() {
      return isLoggedIn();
    },
    showDeleteAction() {
      return this.canDelete && !this.canReportAsAbuse && !this.noteUrl;
    },
    authorBadgeTitle() {
      switch (this.noteableType) {
        case constants.COMMIT_NOTEABLE_TYPE:
          return __('Commit author');
        case constants.MERGE_REQUEST_NOTEABLE_TYPE:
          return __('Merge request author');
        default:
          return undefined;
      }
    },
    displayMemberBadgeText() {
      return sprintf(__('This user has the %{access} role in the %{name} project.'), {
        access: this.accessLevel.toLowerCase(),
        name: this.projectName,
      });
    },
    displayContributorBadgeText() {
      return sprintf(__('This user has previously committed to the %{name} project.'), {
        name: this.projectName,
      });
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <user-access-role-badge
      v-if="isAuthor"
      v-gl-tooltip
      class="gl-mr-3 gl-hidden @sm/panel:gl-block"
      :title="authorBadgeTitle"
    >
      {{ __('Author') }}
    </user-access-role-badge>
    <user-access-role-badge
      v-if="accessLevel"
      v-gl-tooltip
      class="gl-mr-3 gl-hidden @sm/panel:gl-block"
      :title="displayMemberBadgeText"
    >
      {{ accessLevel }}
    </user-access-role-badge>
    <user-access-role-badge
      v-else-if="isContributor"
      v-gl-tooltip
      class="gl-mr-3 gl-hidden @sm/panel:gl-block"
      :title="displayContributorBadgeText"
    >
      {{ __('Contributor') }}
    </user-access-role-badge>
    <span class="note-actions__mobile-spacer"></span>
    <emoji-picker
      v-if="canAwardEmoji"
      toggle-class="add-reaction-button btn-default-tertiary"
      data-testid="note-emoji-button"
      @click="$emit('award', $event)"
    />
    <reply-button
      v-if="showReply"
      ref="replyButton"
      class="js-reply-button"
      @startReplying="$emit('startReplying')"
    />
    <gl-button
      v-if="canEdit"
      v-gl-tooltip
      :title="$options.i18n.editCommentLabel"
      :aria-label="$options.i18n.editCommentLabel"
      icon="pencil"
      category="tertiary"
      class="note-action-button js-note-edit"
      data-testid="note-edit-button"
      @click="$emit('startEditing')"
    />
    <gl-button
      v-if="showDeleteAction"
      v-gl-tooltip
      :title="$options.i18n.deleteCommentLabel"
      :aria-label="$options.i18n.deleteCommentLabel"
      icon="remove"
      category="tertiary"
      class="note-action-button js-note-delete"
      @click="$emit('delete')"
    />
    <div v-else-if="shouldShowActionsDropdown" class="more-actions dropdown">
      <gl-disclosure-dropdown
        v-gl-tooltip
        :title="$options.i18n.moreActionsLabel"
        :toggle-text="$options.i18n.moreActionsLabel"
        text-sr-only
        icon="ellipsis_v"
        category="tertiary"
        placement="bottom-end"
        class="note-action-button more-actions-toggle"
        no-caret
      >
        <gl-disclosure-dropdown-item
          v-if="noteUrl"
          class="js-btn-copy-note-link"
          :data-clipboard-text="noteUrl"
          @action="$toast.show(__('Link copied to clipboard.'))"
        >
          <template #list-item>{{ __('Copy link') }}</template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-group v-if="canReportAsAbuse || canEdit" bordered>
          <gl-disclosure-dropdown-item
            v-if="canReportAsAbuse"
            data-testid="report-abuse-button"
            @action="abuseDrawerOpen = true"
          >
            <template #list-item>{{ $options.i18n.reportAbuse }}</template>
          </gl-disclosure-dropdown-item>
          <gl-disclosure-dropdown-item
            v-if="canEdit"
            class="js-note-delete"
            variant="danger"
            @action="$emit('delete')"
          >
            <template #list-item>{{ __('Delete comment') }}</template>
          </gl-disclosure-dropdown-item>
        </gl-disclosure-dropdown-group>
      </gl-disclosure-dropdown>
    </div>
    <abuse-category-selector
      v-if="canReportAsAbuse && abuseDrawerOpen"
      :reported-user-id="authorId"
      :reported-from-url="noteUrl"
      :show-drawer="abuseDrawerOpen"
      @close-drawer="abuseDrawerOpen = false"
    />
  </div>
</template>
