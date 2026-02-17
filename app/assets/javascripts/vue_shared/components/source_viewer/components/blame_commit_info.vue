<script>
import uniqueId from 'lodash/uniqueId';
import { GlTooltipDirective, GlButton, GlLink, GlTruncate } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { sprintf, __ } from '~/locale';
import defaultAvatarUrl from 'images/no_avatar.png';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import CommitPopover from './commit_popover.vue';

export default {
  name: 'BlameCommitInfo',
  components: {
    GlButton,
    GlLink,
    GlTruncate,
    TimeagoTooltip,
    UserAvatarImage,
    CommitPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
    previousPath: {
      type: String,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      popoverTargetId: uniqueId('blame-commit-popover-'),
    };
  },
  computed: {
    commitTitle() {
      return this.commit.title || '';
    },
    avatarLinkAltText() {
      return sprintf(__(`%{username}'s avatar`), { username: this.commit.authorName });
    },
    avatarUrl() {
      return this.commit.authorGravatar || this.commit.avatarUrl || this.$options.defaultAvatarUrl;
    },
    commitUrl() {
      return this.commit.webPath || this.commit.commitUrl;
    },
    hasMessage() {
      return Boolean(this.commit.message || this.commit.title);
    },
    previousBlameUrl() {
      if (!this.previousPath || !this.commit.parentSha || !this.projectPath) {
        return null;
      }

      const blobPath = joinPaths(
        '/',
        this.projectPath,
        '-/blob',
        this.commit.parentSha,
        this.previousPath,
      );
      return `${blobPath}?blame=1`;
    },
    author() {
      return this.commit.author;
    },
    authorUserId() {
      return this.author?.id ? getIdFromGraphQLId(this.author.id) : null;
    },
    authorUsername() {
      return this.author?.username || '';
    },
    authorWebPath() {
      return this.author?.webPath || '';
    },
    avatarWrapperProps() {
      if (!this.author) return {};
      return {
        href: this.authorWebPath,
        'data-user-id': this.authorUserId,
        'data-username': this.authorUsername,
        class: 'js-user-link',
        'data-testid': 'commit-author-link',
      };
    },
  },
  defaultAvatarUrl,
  i18n: {
    viewBlamePrior: __('View blame prior to this change'),
  },
};
</script>

<template>
  <div
    style="height: var(--blame-line-height)"
    class="gl-flex gl-w-full gl-items-center gl-gap-3"
    data-testid="blame-commit-info"
  >
    <timeago-tooltip
      :time="commit.authoredDate || commit.committedDate"
      tooltip-placement="top"
      class="gl-w-12 gl-shrink-0 gl-truncate gl-text-sm gl-text-secondary"
      data-testid="commit-time"
    />

    <component :is="author ? 'a' : 'span'" v-bind="avatarWrapperProps" class="gl-pb-[0.15rem]">
      <user-avatar-image
        :img-src="avatarUrl"
        :size="16"
        :img-alt="avatarLinkAltText"
        data-testid="commit-author-avatar"
        lazy
      />
    </component>

    <div class="gl-min-w-0 gl-flex-1">
      <gl-link
        :id="popoverTargetId"
        :href="commitUrl"
        :class="{ 'gl-italic': !hasMessage }"
        class="gl-text-sm gl-text-default hover:gl-text-default focus:gl-focus-inset"
        data-testid="commit-message-link"
      >
        <gl-truncate :text="commitTitle" class="gl-pb-2" />
      </gl-link>
      <commit-popover :popover-target-id="popoverTargetId" :commit="commit" class="gl-z-3" />
    </div>

    <gl-button
      v-gl-tooltip
      :href="previousBlameUrl"
      :title="$options.i18n.viewBlamePrior"
      :aria-label="$options.i18n.viewBlamePrior"
      category="tertiary"
      size="small"
      icon="doc-versions"
      data-event-tracking="click_previous_blame_on_blob_page"
      data-testid="view-previous-blame-button"
      style="min-height: var(--blame-line-height)"
      class="!gl-text-secondary focus:!gl-focus-inset"
      :class="{ 'gl-invisible': !previousBlameUrl }"
    />
  </div>
</template>
