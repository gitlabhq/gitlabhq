<script>
import { mapState, mapGetters } from 'vuex';
import { GlAvatar, GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import PackageTags from '../../shared/components/package_tags.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { __ } from '~/locale';

export default {
  name: 'PackageTitle',
  components: {
    GlAvatar,
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
  <div class="gl-flex-direction-column">
    <div class="gl-display-flex">
      <gl-avatar
        v-if="packageIcon"
        :src="packageIcon"
        shape="rect"
        class="gl-align-self-center gl-mr-4"
        data-testid="package-icon"
      />

      <div class="gl-display-flex gl-flex-direction-column">
        <h1 class="gl-font-size-h1 gl-mt-3 gl-mb-2">
          {{ packageEntity.name }}
        </h1>

        <div class="gl-display-flex gl-align-items-center gl-text-gray-700">
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
        </div>
      </div>
    </div>

    <div class="gl-display-flex gl-flex-wrap gl-align-items-center gl-mb-3">
      <div v-if="packageTypeDisplay" class="gl-display-flex gl-align-items-center gl-mr-5">
        <gl-icon name="package" class="gl-text-gray-700 gl-mr-3" />
        <span data-testid="package-type" class="gl-font-weight-bold">{{ packageTypeDisplay }}</span>
      </div>

      <div v-if="hasTagsToDisplay" class="gl-display-flex gl-align-items-center gl-mr-5">
        <package-tags :tag-display-limit="1" :tags="packageEntity.tags" />
      </div>

      <div v-if="packagePipeline" class="gl-display-flex gl-align-items-center gl-mr-5">
        <gl-icon name="review-list" class="gl-text-gray-700 gl-mr-3" />
        <gl-link
          data-testid="pipeline-project"
          :href="packagePipeline.project.web_url"
          class="gl-font-weight-bold text-truncate"
        >
          {{ packagePipeline.project.name }}
        </gl-link>
      </div>

      <div
        v-if="packagePipeline"
        data-testid="package-ref"
        class="gl-display-flex gl-align-items-center gl-mr-5"
      >
        <gl-icon name="branch" class="gl-text-gray-700 gl-mr-3" />
        <span
          v-gl-tooltip
          class="gl-font-weight-bold text-truncate mw-xs"
          :title="packagePipeline.ref"
          >{{ packagePipeline.ref }}</span
        >
      </div>

      <div class="gl-display-flex gl-align-items-center gl-mr-5">
        <gl-icon name="disk" class="gl-text-gray-700 gl-mr-3" />
        <span data-testid="package-size" class="gl-font-weight-bold">{{ totalSize }}</span>
      </div>
    </div>
  </div>
</template>
