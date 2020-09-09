<script>
import { mapState, mapGetters } from 'vuex';
import { GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import PackageTags from '../../shared/components/package_tags.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { __ } from '~/locale';

export default {
  name: 'PackageTitle',
  components: {
    TitleArea,
    GlIcon,
    GlLink,
    GlSprintf,
    PackageTags,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
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
  i18n: {
    packageInfo: __('v%{version} published %{timeAgo}'),
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

    <template v-if="packageTypeDisplay" #metadata_type>
      <gl-icon name="package" class="gl-text-gray-500 gl-mr-3" />
      <span data-testid="package-type" class="gl-font-weight-bold">{{ packageTypeDisplay }}</span>
    </template>

    <template #metadata_size>
      <gl-icon name="disk" class="gl-text-gray-500 gl-mr-3" />
      <span data-testid="package-size" class="gl-font-weight-bold">{{ totalSize }}</span>
    </template>

    <template v-if="packagePipeline" #metadata_pipeline>
      <gl-icon name="review-list" class="gl-text-gray-500 gl-mr-3" />
      <gl-link
        data-testid="pipeline-project"
        :href="packagePipeline.project.web_url"
        class="gl-font-weight-bold gl-str-truncated"
      >
        {{ packagePipeline.project.name }}
      </gl-link>
    </template>

    <template v-if="packagePipeline" #metadata_ref>
      <gl-icon name="branch" data-testid="package-ref-icon" class="gl-text-gray-500 gl-mr-3" />
      <span
        v-gl-tooltip
        data-testid="package-ref"
        class="gl-font-weight-bold gl-str-truncated mw-xs"
        :title="packagePipeline.ref"
        >{{ packagePipeline.ref }}</span
      >
    </template>

    <template v-if="hasTagsToDisplay" #metadata_tags>
      <package-tags :tag-display-limit="2" :tags="packageEntity.tags" hide-label />
    </template>

    <template #right-actions>
      <slot name="delete-button"></slot>
    </template>
  </title-area>
</template>
