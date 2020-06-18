<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import ReleaseBlockAuthor from './release_block_author.vue';
import ReleaseBlockMilestones from './release_block_milestones.vue';

export default {
  name: 'ReleaseBlockMetadata',
  components: {
    Icon,
    GlLink,
    ReleaseBlockAuthor,
    ReleaseBlockMilestones,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    release: {
      type: Object,
      required: true,
    },
  },
  computed: {
    author() {
      return this.release.author;
    },
    commit() {
      return this.release.commit || {};
    },
    commitUrl() {
      return this.release.commitPath;
    },
    hasAuthor() {
      return Boolean(this.author);
    },
    releasedTimeAgo() {
      const now = new Date();
      const isFuture = now < new Date(this.release.releasedAt);
      const time = this.timeFormatted(this.release.releasedAt);
      return isFuture
        ? sprintf(__('will be released %{time}'), { time })
        : sprintf(__('released %{time}'), { time });
    },
    shouldRenderMilestones() {
      return Boolean(this.release.milestones?.length);
    },
    tagUrl() {
      return this.release.tagPath;
    },
  },
};
</script>

<template>
  <div class="card-subtitle d-flex flex-wrap text-secondary">
    <div class="gl-mr-3">
      <icon name="commit" class="align-middle" />
      <gl-link v-if="commitUrl" v-gl-tooltip.bottom :title="commit.title" :href="commitUrl">
        {{ commit.shortId }}
      </gl-link>
      <span v-else v-gl-tooltip.bottom :title="commit.title">{{ commit.shortId }}</span>
    </div>

    <div class="gl-mr-3">
      <icon name="tag" class="align-middle" />
      <gl-link v-if="tagUrl" v-gl-tooltip.bottom :title="__('Tag')" :href="tagUrl">
        {{ release.tagName }}
      </gl-link>
      <span v-else v-gl-tooltip.bottom :title="__('Tag')">{{ release.tagName }}</span>
    </div>

    <release-block-milestones v-if="shouldRenderMilestones" :milestones="release.milestones" />

    <div class="append-right-4">
      &bull;
      <span
        v-gl-tooltip.bottom
        class="js-release-date-info"
        :title="tooltipTitle(release.releasedAt)"
      >
        {{ releasedTimeAgo }}
      </span>
    </div>

    <release-block-author v-if="hasAuthor" :author="author" />
  </div>
</template>
