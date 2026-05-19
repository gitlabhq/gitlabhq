<script>
import { GlTooltipDirective, GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { RELEASED_AT_ASC, RELEASED_AT_DESC } from '~/releases/constants';

export default {
  name: 'ReleaseBlockDetails',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
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
    previousReleaseSha: {
      type: String,
      required: false,
      default: '',
    },
    comparePath: {
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
    releaseCommitTitle() {
      return sprintf(this.$options.i18n.releaseCommit, { commit: this.commit.title }, false);
    },
  },
  i18n: {
    dateString: __('%{action} %{date}'),
    releaseCommit: __('Release commit: %{commit}'),
  },
};
</script>
<template>
  <div
    class="gl-grid gl-shrink-0 gl-grid-cols-1 gl-gap-3 gl-text-sm @sm:gl-grid-cols-2 @md:gl-flex @md:gl-w-31 @md:gl-flex-col"
  >
    <div class="gl-flex gl-flex-col gl-gap-3">
      <div>
        <user-avatar-link
          v-if="author"
          :link-href="author.webPath"
          :img-src="author.avatarUrl"
          :img-alt="userImageAltDescription"
          :img-size="16"
          :username="author.name"
          :popover-username="author.username"
          :popover-user-id="author.id"
          img-css-wrapper-classes="gl-mr-1"
          class="gl-items-center gl-leading-0 gl-text-subtle"
        />
      </div>
      <div v-if="timeAt" class="gl-flex gl-gap-2 gl-text-subtle">
        <gl-icon ref="dateIcon" name="calendar" variant="subtle" />

        <div>
          <gl-sprintf :message="$options.i18n.dateString">
            <template #action>{{ createdTime }}</template>
            <template #date>
              <span v-gl-tooltip.bottom :title="tooltipTitle(timeAt)">{{ atTimeAgo }}</span>
            </template>
          </gl-sprintf>
        </div>
      </div>
    </div>

    <div class="gl-flex gl-flex-col gl-gap-3">
      <div v-if="commit">
        <div class="js-commit-info gl-flex gl-items-center gl-gap-2">
          <gl-icon ref="commitIcon" name="commit" variant="subtle" />
          <div v-gl-tooltip.bottom :title="releaseCommitTitle">
            <gl-link
              v-if="commitPath"
              :href="commitPath"
              class="gl-mr-0 gl-font-monospace gl-text-subtle"
            >
              {{ commit.shortId }}
            </gl-link>
            <span v-else class="gl-font-monospace">{{ commit.shortId }}</span>
          </div>
        </div>
      </div>

      <div
        v-if="commit && previousReleaseSha && comparePath"
        data-testid="compare-info"
        class="gl-flex gl-gap-2"
      >
        <gl-icon name="comparison" variant="subtle" />
        <gl-link
          v-gl-tooltip.bottom
          :href="comparePath"
          class="gl-mr-0 gl-font-monospace gl-text-subtle"
          :title="__('Compare to previous release')"
        >
          {{ previousReleaseSha.slice(0, 7) }}...{{ commit.shortId }}
        </gl-link>
      </div>

      <div v-if="tagName" class="js-tag-info gl-flex gl-gap-2">
        <gl-icon name="tag" variant="subtle" />
        <div v-gl-tooltip.bottom :title="__('Tag')">
          <gl-link v-if="tagPath" :href="tagPath" class="gl-mr-0 gl-font-monospace gl-text-subtle">
            {{ tagName }}
          </gl-link>
          <span v-else>{{ tagName }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
