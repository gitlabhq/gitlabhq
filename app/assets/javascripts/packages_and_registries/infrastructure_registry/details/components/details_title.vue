<script>
import { GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  name: 'DetailsTitle',
  components: {
    TitleArea,
    GlIcon,
    GlSprintf,
    MetadataItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  i18n: {
    packageInfo: __('v%{version} published %{timeAgo}'),
  },
  computed: {
    ...mapState(['packageEntity', 'packageFiles']),
    ...mapGetters(['packagePipeline']),
    totalSize() {
      return numberToHumanSize(this.packageFiles.reduce((acc, p) => acc + p.size, 0));
    },
  },
};
</script>

<template>
  <title-area :title="packageEntity.name">
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

    <template #metadata-type>
      <metadata-item data-testid="package-type" icon="infrastructure-registry" text="Terraform" />
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

    <template #right-actions>
      <slot name="delete-button"></slot>
    </template>
  </title-area>
</template>
