<script>
import { GlBadge, GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  name: 'PackageTags',
  components: {
    GlBadge,
    GlIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tagDisplayLimit: {
      type: Number,
      required: false,
      default: 2,
    },
    tags: {
      type: Array,
      required: true,
      default: () => [],
    },
    hideLabel: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    tagCount() {
      return this.tags.length;
    },
    tagsToRender() {
      return this.tags.slice(0, this.tagDisplayLimit);
    },
    moreTagsDisplay() {
      return Math.max(0, this.tags.length - this.tagDisplayLimit);
    },
    moreTagsTooltip() {
      if (this.moreTagsDisplay) {
        return this.tags
          .slice(this.tagDisplayLimit)
          .map(x => x.name)
          .join(', ');
      }

      return '';
    },
    tagsDisplay() {
      return n__('%d tag', '%d tags', this.tagCount);
    },
  },
  methods: {
    tagBadgeClass(index) {
      return {
        'gl-display-none': true,
        'gl-display-flex': this.tagCount === 1,
        'd-md-flex': this.tagCount > 1,
        'gl-mr-2': index !== this.tagsToRender.length - 1,
        'gl-ml-3': !this.hideLabel && index === 0,
      };
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <div v-if="!hideLabel" data-testid="tagLabel" class="gl-display-flex gl-align-items-center">
      <gl-icon name="labels" class="gl-text-gray-700 gl-mr-3" />
      <span class="gl-font-weight-bold">{{ tagsDisplay }}</span>
    </div>

    <gl-badge
      v-for="(tag, index) in tagsToRender"
      :key="index"
      data-testid="tagBadge"
      :class="tagBadgeClass(index)"
      variant="info"
      >{{ tag.name }}</gl-badge
    >

    <gl-badge
      v-if="moreTagsDisplay"
      v-gl-tooltip
      data-testid="moreBadge"
      variant="muted"
      :title="moreTagsTooltip"
      class="gl-display-none d-md-flex gl-ml-2"
      ><gl-sprintf :message="__('+%{tags} more')">
        <template #tags>
          {{ moreTagsDisplay }}
        </template>
      </gl-sprintf></gl-badge
    >

    <gl-badge
      v-if="moreTagsDisplay && hideLabel"
      data-testid="moreBadge"
      variant="muted"
      class="d-md-none gl-ml-2"
      >{{ tagsDisplay }}</gl-badge
    >
  </div>
</template>
