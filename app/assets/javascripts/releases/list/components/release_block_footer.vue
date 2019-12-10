<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { __, sprintf } from '~/locale';

export default {
  name: 'ReleaseBlockFooter',
  components: {
    Icon,
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
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    releasedAtTimeAgo() {
      return this.timeFormated(this.releasedAt);
    },
    userImageAltDescription() {
      return this.author && this.author.username
        ? sprintf(__("%{username}'s avatar"), { username: this.author.username })
        : null;
    },
  },
};
</script>
<template>
  <div>
    <div v-if="commit" class="float-left mr-3 d-flex align-items-center js-commit-info">
      <icon ref="commitIcon" name="commit" class="mr-1" />
      <div v-gl-tooltip.bottom :title="commit.title">
        <gl-link v-if="commitPath" :href="commitPath">
          {{ commit.short_id }}
        </gl-link>
        <span v-else>{{ commit.short_id }}</span>
      </div>
    </div>

    <div v-if="tagName" class="float-left mr-3 d-flex align-items-center js-tag-info">
      <icon name="tag" class="mr-1" />
      <div v-gl-tooltip.bottom :title="__('Tag')">
        <gl-link v-if="tagPath" :href="tagPath">
          {{ tagName }}
        </gl-link>
        <span v-else>{{ tagName }}</span>
      </div>
    </div>

    <div
      v-if="releasedAt || author"
      class="float-left d-flex align-items-center js-author-date-info"
    >
      <span class="text-secondary">{{ __('Created') }}&nbsp;</span>
      <template v-if="releasedAt">
        <span
          v-gl-tooltip.bottom
          :title="tooltipTitle(releasedAt)"
          class="text-secondary flex-shrink-0"
        >
          {{ releasedAtTimeAgo }}&nbsp;
        </span>
      </template>

      <div v-if="author" class="d-flex">
        <span class="text-secondary">{{ __('by') }}&nbsp;</span>
        <user-avatar-link
          :link-href="author.web_url"
          :img-src="author.avatar_url"
          :img-alt="userImageAltDescription"
          :tooltip-text="author.username"
          tooltip-placement="bottom"
        />
      </div>
    </div>
  </div>
</template>
