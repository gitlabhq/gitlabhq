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
      return this.release.commit_path;
    },
    hasAuthor() {
      return Boolean(this.author);
    },
    releasedTimeAgo() {
      return sprintf(__('released %{time}'), {
        time: this.timeFormatted(this.release.released_at),
      });
    },
    shouldRenderMilestones() {
      return Boolean(this.release.milestones?.length);
    },
    tagUrl() {
      return this.release.tag_path;
    },
  },
};
</script>

<template>
  <div class="card-subtitle d-flex flex-wrap text-secondary">
    <div class="append-right-8">
      <icon name="commit" class="align-middle" />
      <gl-link v-if="commitUrl" v-gl-tooltip.bottom :title="commit.title" :href="commitUrl">
        {{ commit.short_id }}
      </gl-link>
      <span v-else v-gl-tooltip.bottom :title="commit.title">{{ commit.short_id }}</span>
    </div>

    <div class="append-right-8">
      <icon name="tag" class="align-middle" />
      <gl-link v-if="tagUrl" v-gl-tooltip.bottom :title="__('Tag')" :href="tagUrl">
        {{ release.tag_name }}
      </gl-link>
      <span v-else v-gl-tooltip.bottom :title="__('Tag')">{{ release.tag_name }}</span>
    </div>

    <release-block-milestones v-if="shouldRenderMilestones" :milestones="release.milestones" />

    <div class="append-right-4">
      &bull;
      <span v-gl-tooltip.bottom :title="tooltipTitle(release.released_at)">
        {{ releasedTimeAgo }}
      </span>
    </div>

    <release-block-author v-if="hasAuthor" :author="author" />
  </div>
</template>
