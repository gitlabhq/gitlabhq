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
  <div class="gl-flex gl-items-center gl-gap-5 gl-text-sm">
    <div v-if="commit" class="js-commit-info gl-flex gl-items-center gl-gap-2">
      <gl-icon ref="commitIcon" name="commit" variant="subtle" />
      <div v-gl-tooltip.bottom :title="commit.title">
        <gl-link
          v-if="commitPath"
          :href="commitPath"
          class="gl-mr-0 gl-text-subtle gl-font-monospace"
        >
          {{ commit.shortId }}
        </gl-link>
        <span v-else>{{ commit.shortId }}</span>
      </div>
    </div>

    <div v-if="tagName" class="js-tag-info gl-flex gl-items-center gl-gap-2">
      <gl-icon name="tag" variant="subtle" />
      <div v-gl-tooltip.bottom :title="__('Tag')">
        <gl-link v-if="tagPath" :href="tagPath" class="gl-mr-0 gl-text-subtle gl-font-monospace">
          {{ tagName }}
        </gl-link>
        <span v-else>{{ tagName }}</span>
      </div>
    </div>
    <div v-if="timeAt || author" class="js-author-date-info gl-flex gl-items-center">
      <span class="gl-text-subtle">{{ createdTime }}&nbsp;</span>
      <template v-if="timeAt">
        <span v-gl-tooltip.bottom :title="tooltipTitle(timeAt)" class="gl-shrink-0 gl-text-subtle">
          {{ atTimeAgo }}&nbsp;
        </span>
      </template>

      <div v-if="author" class="gl-flex gl-items-center gl-gap-1">
        <span class="gl-text-subtle">{{ __('by') }}&nbsp;</span>
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
