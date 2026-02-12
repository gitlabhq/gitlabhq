<script>
import { GlPopover, GlLink, GlAvatar, GlIcon, GlTruncate } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import defaultAvatarUrl from 'images/no_avatar.png';

export default {
  name: 'CommitPopover',
  components: {
    GlPopover,
    GlLink,
    GlAvatar,
    GlIcon,
    GlTruncate,
  },
  props: {
    popoverTargetId: {
      type: String,
      required: true,
    },
    commit: {
      type: Object,
      required: true,
    },
  },
  computed: {
    authorName() {
      return this.commit.author?.name || this.commit.authorName || '';
    },
    avatarUrl() {
      return (
        this.commit.author?.avatarUrl ||
        this.commit.authorGravatar ||
        this.commit.avatarUrl ||
        defaultAvatarUrl
      );
    },
    authoredDate() {
      return this.commit.authoredDate;
    },
    commitUrl() {
      return this.commit.webPath || this.commit.commitUrl;
    },
    authoredText() {
      if (!this.authoredDate) return '';
      const timeago = getTimeago().format(new Date(this.authoredDate));
      return sprintf(__('Authored %{timeago}'), { timeago });
    },
  },
};
</script>

<template>
  <gl-popover
    :container="popoverTargetId"
    :target="popoverTargetId"
    placement="top"
    boundary="viewport"
    data-testid="commit-popover"
  >
    <div class="gl-flex gl-flex-col gl-gap-3">
      <!-- Authored time -->
      <div class="gl-text-secondary" data-testid="commit-authored-time">
        {{ authoredText }}
      </div>

      <!-- Commit title -->
      <gl-link
        :href="commitUrl"
        class="gl-text-default hover:gl-text-default"
        data-testid="commit-title-link"
      >
        <gl-truncate :text="commit.title" :lines="2" class="gl-font-bold" />
      </gl-link>

      <!-- Author info -->
      <div class="gl-flex gl-items-center gl-gap-2 gl-text-secondary">
        <gl-avatar :src="avatarUrl" :size="16" :alt="authorName" />
        <span data-testid="commit-author">{{ authorName }}</span>
      </div>

      <!-- Commit SHA -->
      <div class="gl-flex gl-items-center gl-gap-2">
        <gl-icon name="commit" :size="14" class="gl-text-secondary" />
        <gl-link
          :href="commitUrl"
          class="gl-font-monospace gl-text-secondary hover:gl-text-default"
          data-testid="commit-sha-link"
        >
          {{ commit.shortId }}
        </gl-link>
      </div>
    </div>
  </gl-popover>
</template>
