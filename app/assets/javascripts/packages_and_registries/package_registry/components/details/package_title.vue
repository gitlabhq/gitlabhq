<script>
import { GlSprintf, GlBadge, GlResizeObserverDirective } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import { __, s__, sprintf } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import { PACKAGE_TYPE_NUGET } from '~/packages_and_registries/package_registry/constants';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'PackageTitle',
  components: {
    TitleArea,
    GlSprintf,
    PackageTags,
    MetadataItem,
    GlBadge,
    TimeAgoTooltip,
    ProtectedBadge,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  inject: ['isGroupPage'],
  i18n: {
    lastDownloadedAt: s__('PackageRegistry|Last downloaded %{dateTime}'),
    packageInfo: __('v%{version} published %{timeAgo}'),
    badgeProtectedTooltipText: s__('PackageRegistry|A protection rule exists for this package.'),
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDesktop: true,
    };
  },
  computed: {
    packageLastDownloadedAtDisplay() {
      return sprintf(this.$options.i18n.lastDownloadedAt, {
        dateTime: formatDate(this.packageEntity.lastDownloadedAt, 'mmm d, yyyy'),
      });
    },
    packageTypeDisplay() {
      return getPackageTypeLabel(this.packageEntity.packageType);
    },
    packagePipeline() {
      return this.packageEntity.pipelines?.nodes[0];
    },
    packageIcon() {
      if (this.packageEntity.packageType === PACKAGE_TYPE_NUGET) {
        return this.packageEntity.metadata?.iconUrl || null;
      }
      return null;
    },
    hasTagsToDisplay() {
      return Boolean(this.packageEntity.tags?.nodes && this.packageEntity.tags?.nodes.length);
    },
    showBadgeProtected() {
      return Boolean(this.packageEntity?.protectionRuleExists);
    },
  },
  mounted() {
    this.checkBreakpoints();
  },
  methods: {
    checkBreakpoints() {
      this.isDesktop = GlBreakpointInstance.isDesktop();
    },
  },
};
</script>

<template>
  <title-area
    v-gl-resize-observer="checkBreakpoints"
    :title="packageEntity.name"
    :avatar="packageIcon"
  >
    <template #sub-header>
      <div data-testid="sub-header" class="gl-flex gl-flex-wrap gl-items-baseline gl-gap-2">
        <gl-sprintf :message="$options.i18n.packageInfo">
          <template #version>{{ packageEntity.version }}</template>

          <template #timeAgo>
            <time-ago-tooltip v-if="packageEntity.createdAt" :time="packageEntity.createdAt" />
          </template>
        </gl-sprintf>

        <package-tags
          v-if="isDesktop && hasTagsToDisplay"
          :tag-display-limit="2"
          :tags="packageEntity.tags.nodes"
          hide-label
        />

        <!-- we need to duplicate the package tags on mobile to ensure proper styling inside the flex wrap -->
        <template v-else-if="hasTagsToDisplay">
          <gl-badge
            v-for="(tag, index) in packageEntity.tags.nodes"
            :key="index"
            class="gl-my-1"
            data-testid="tag-badge"
            variant="info"
          >
            {{ tag.name }}
          </gl-badge>
        </template>

        <protected-badge
          v-if="showBadgeProtected"
          :tooltip-text="$options.i18n.badgeProtectedTooltipText"
        />
      </div>
    </template>

    <template v-if="packageTypeDisplay" #metadata-type>
      <metadata-item data-testid="package-type" icon="package" :text="packageTypeDisplay" />
    </template>

    <template v-if="isGroupPage && packagePipeline" #metadata-pipeline>
      <metadata-item
        data-testid="pipeline-project"
        icon="review-list"
        :text="packagePipeline.project.name"
        :link="packagePipeline.project.webUrl"
      />
    </template>

    <template v-if="packagePipeline && packagePipeline.ref" #metadata-ref>
      <metadata-item data-testid="package-ref" icon="branch" :text="packagePipeline.ref" />
    </template>

    <template v-if="packageEntity.lastDownloadedAt" #metadata-last-downloaded-at>
      <metadata-item
        data-testid="package-last-downloaded-at"
        icon="download"
        :text="packageLastDownloadedAtDisplay"
        size="m"
      />
    </template>

    <template #right-actions>
      <slot name="delete-button"></slot>
    </template>
  </title-area>
</template>
