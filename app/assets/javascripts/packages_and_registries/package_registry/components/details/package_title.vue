<script>
import { GlSprintf, GlResizeObserverDirective } from '@gitlab/ui';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import { __, s__, sprintf } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { newDate } from '~/lib/utils/datetime_utility';
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
  computed: {
    packageLastDownloadedAtDisplay() {
      return sprintf(this.$options.i18n.lastDownloadedAt, {
        dateTime: localeDateFormat.asDate.format(newDate(this.packageEntity.lastDownloadedAt)),
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
};
</script>

<template>
  <title-area :title="packageEntity.name" :avatar="packageIcon" :inline-actions="false">
    <template #sub-header>
      <div data-testid="sub-header" class="gl-flex gl-flex-wrap gl-items-baseline gl-gap-2">
        <gl-sprintf :message="$options.i18n.packageInfo">
          <template #version>{{ packageEntity.version }}</template>

          <template #timeAgo>
            <time-ago-tooltip v-if="packageEntity.createdAt" :time="packageEntity.createdAt" />
          </template>
        </gl-sprintf>

        <package-tags
          v-if="hasTagsToDisplay"
          :tag-display-limit="2"
          :tags="packageEntity.tags.nodes"
          hide-label
        />

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
