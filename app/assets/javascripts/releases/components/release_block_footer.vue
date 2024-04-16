<script>
import { GlTooltipDirective, GlLink, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { RELEASED_AT_ASC, RELEASED_AT_DESC } from '~/releases/constants';

export default {
  name: 'ReleaseBlockFooter',
  components: {
    GlIcon,
    GlLink,
    UserAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    commit: {
      type: Object,
      required: false,
      default: null,
    },
    commitPath: {
      type: String,
      required: false,
      default: '',
    },
    tagName: {
      type: String,
      required: false,
      default: '',
    },
    tagPath: {
      type: String,
      required: false,
      default: '',
    },
    author: {
      type: Object,
      required: false,
      default: null,
    },
    releasedAt: {
      type: Date,
      required: false,
      default: null,
    },
    createdAt: {
      type: Date,
      required: false,
      default: null,
    },
    sort: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isSortedByReleaseDate() {
      return this.sort === RELEASED_AT_ASC || this.sort === RELEASED_AT_DESC;
    },
    timeAt() {
      return this.isSortedByReleaseDate ? this.releasedAt : this.createdAt;
    },
    atTimeAgo() {
      return this.timeFormatted(this.timeAt);
    },
    userImageAltDescription() {
      return this.author && this.author.username
        ? sprintf(__("%{username}'s avatar"), { username: this.author.username })
        : null;
    },
    createdTime() {
      const now = new Date();
      const isFuture = now < new Date(this.timeAt);
      if (this.isSortedByReleaseDate) {
        return isFuture ? __('Will be released') : __('Released');
      }
      return isFuture ? __('Will be created') : __('Created');
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-gap-5">
    <div v-if="commit" class="gl-display-flex gl-align-items-center js-commit-info">
      <gl-icon ref="commitIcon" name="commit" class="gl-mr-2 gl-text-gray-700" />
      <div v-gl-tooltip.bottom :title="commit.title">
        <gl-link
          v-if="commitPath"
          :href="commitPath"
          class="gl-font-sm gl-font-monospace gl-mr-0 gl-text-gray-700"
        >
          {{ commit.shortId }}
        </gl-link>
        <span v-else>{{ commit.shortId }}</span>
      </div>
    </div>

    <div v-if="tagName" class="gl-display-flex gl-align-items-center js-tag-info">
      <gl-icon name="tag" class="gl-mr-2 gl-text-gray-700" />
      <div v-gl-tooltip.bottom :title="__('Tag')">
        <gl-link
          v-if="tagPath"
          :href="tagPath"
          class="gl-font-sm gl-font-monospace gl-mr-0 gl-text-gray-700"
        >
          {{ tagName }}
        </gl-link>
        <span v-else>{{ tagName }}</span>
      </div>
    </div>
    <div
      v-if="timeAt || author"
      class="gl-display-flex gl-align-items-center js-author-date-info gl-font-sm"
    >
      <span class="gl-text-secondary">{{ createdTime }}&nbsp;</span>
      <template v-if="timeAt">
        <span
          v-gl-tooltip.bottom
          :title="tooltipTitle(timeAt)"
          class="gl-text-secondary gl-flex-shrink-0"
        >
          {{ atTimeAgo }}&nbsp;
        </span>
      </template>

      <div v-if="author" class="gl-display-flex">
        <span class="gl-text-secondary">{{ __('by') }}&nbsp;</span>
        <user-avatar-link
          :link-href="author.webUrl"
          :img-src="author.avatarUrl"
          :img-alt="userImageAltDescription"
          :img-size="16"
          :tooltip-text="author.username"
          tooltip-placement="bottom"
        />
      </div>
    </div>
  </div>
</template>
