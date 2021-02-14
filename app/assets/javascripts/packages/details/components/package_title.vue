<script>
/* eslint-disable vue/v-slot-style */
import { GlIcon, GlSprintf, GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { mapState, mapGetters } from 'vuex';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import PackageTags from '../../shared/components/package_tags.vue';

export default {
  name: 'PackageTitle',
  components: {
    TitleArea,
    GlIcon,
    GlSprintf,
    PackageTags,
    MetadataItem,
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  i18n: {
    packageInfo: __('v%{version} published %{timeAgo}'),
  },
  data() {
    return {
      isDesktop: true,
    };
  },
  computed: {
    ...mapState(['packageEntity', 'packageFiles']),
    ...mapGetters(['packageTypeDisplay', 'packagePipeline', 'packageIcon']),
    hasTagsToDisplay() {
      return Boolean(this.packageEntity.tags && this.packageEntity.tags.length);
    },
    totalSize() {
      return numberToHumanSize(this.packageFiles.reduce((acc, p) => acc + p.size, 0));
    },
  },
  mounted() {
    this.isDesktop = GlBreakpointInstance.isDesktop();
  },
  methods: {
    dynamicSlotName(index) {
      return `metadata-tag${index}`;
    },
  },
};
</script>

<template>
  <title-area :title="packageEntity.name" :avatar="packageIcon" data-qa-selector="package_title">
    <template #sub-header>
      <gl-icon name="eye" class="gl-mr-3" />
      <gl-sprintf :message="$options.i18n.packageInfo">
        <template #version>
          {{ packageEntity.version }}
        </template>

        <template #timeAgo>
          <span v-gl-tooltip :title="tooltipTitle(packageEntity.created_at)">
            &nbsp;{{ timeFormatted(packageEntity.created_at) }}
          </span>
        </template>
      </gl-sprintf>
    </template>

    <template v-if="packageTypeDisplay" #metadata-type>
      <metadata-item data-testid="package-type" icon="package" :text="packageTypeDisplay" />
    </template>

    <template #metadata-size>
      <metadata-item data-testid="package-size" icon="disk" :text="totalSize" />
    </template>

    <template v-if="packagePipeline" #metadata-pipeline>
      <metadata-item
        data-testid="pipeline-project"
        icon="review-list"
        :text="packagePipeline.project.name"
        :link="packagePipeline.project.web_url"
      />
    </template>

    <template v-if="packagePipeline" #metadata-ref>
      <metadata-item data-testid="package-ref" icon="branch" :text="packagePipeline.ref" />
    </template>

    <template v-if="isDesktop && hasTagsToDisplay" #metadata-tags>
      <package-tags :tag-display-limit="2" :tags="packageEntity.tags" hide-label />
    </template>

    <!-- we need to duplicate the package tags on mobile to ensure proper styling inside the flex wrap -->
    <template
      v-for="(tag, index) in packageEntity.tags"
      v-else-if="hasTagsToDisplay"
      v-slot:[dynamicSlotName(index)]
    >
      <gl-badge :key="index" class="gl-my-1" data-testid="tag-badge" variant="info" size="sm">
        {{ tag.name }}
      </gl-badge>
    </template>

    <template #right-actions>
      <slot name="delete-button"></slot>
    </template>
  </title-area>
</template>
