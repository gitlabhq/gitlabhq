<script>
import { mapState, mapGetters } from 'vuex';
import { GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import PackageTags from '../../shared/components/package_tags.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import { __ } from '~/locale';

export default {
  name: 'PackageTitle',
  components: {
    TitleArea,
    GlIcon,
    GlSprintf,
    PackageTags,
    MetadataItem,
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

    <template v-if="hasTagsToDisplay" #metadata-tags>
      <package-tags :tag-display-limit="2" :tags="packageEntity.tags" hide-label />
    </template>

    <template #right-actions>
      <slot name="delete-button"></slot>
    </template>
  </title-area>
</template>
