<script>
import { GlButton, GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import PackageTags from './package_tags.vue';
import PublishMethod from './publish_method.vue';
import { getPackageTypeLabel } from '../utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import ListItem from '~/vue_shared/components/registry/list_item.vue';

export default {
  name: 'PackageListRow',
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    PackageTags,
    PublishMethod,
    ListItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
    packageLink: {
      type: String,
      required: true,
    },
    disableDelete: {
      type: Boolean,
      default: false,
      required: false,
    },
    isGroup: {
      type: Boolean,
      default: false,
      required: false,
    },
    showPackageType: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  computed: {
    packageType() {
      return getPackageTypeLabel(this.packageEntity.package_type);
    },
    hasPipeline() {
      return Boolean(this.packageEntity.pipeline);
    },
    hasProjectLink() {
      return Boolean(this.packageEntity.project_path);
    },
  },
};
</script>

<template>
  <list-item data-qa-selector="packages-row">
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center gl-mr-3">
        <gl-link :href="packageLink" class="gl-text-body" data-qa-selector="package_link">
          {{ packageEntity.name }}
        </gl-link>

        <package-tags
          v-if="packageEntity.tags && packageEntity.tags.length"
          class="gl-ml-3"
          :tags="packageEntity.tags"
          hide-label
          :tag-display-limit="1"
        />
      </div>
    </template>
    <template #left-secondary>
      <div class="gl-display-flex">
        <span>{{ packageEntity.version }}</span>

        <div v-if="hasPipeline" class="gl-display-none gl-display-sm-flex gl-ml-2">
          <gl-sprintf :message="s__('PackageRegistry|published by %{author}')">
            <template #author>{{ packageEntity.pipeline.user.name }}</template>
          </gl-sprintf>
        </div>

        <div v-if="hasProjectLink" class="gl-display-flex gl-align-items-center">
          <gl-icon name="review-list" class="gl-ml-3 gl-mr-2" />

          <gl-link
            class="gl-text-body"
            data-testid="packages-row-project"
            :href="`/${packageEntity.project_path}`"
          >
            {{ packageEntity.projectPathName }}
          </gl-link>
        </div>

        <div v-if="showPackageType" class="d-flex align-items-center" data-testid="package-type">
          <gl-icon name="package" class="gl-ml-3 gl-mr-2" />
          <span>{{ packageType }}</span>
        </div>
      </div>
    </template>

    <template #right-primary>
      <publish-method :package-entity="packageEntity" :is-group="isGroup" />
    </template>

    <template #right-secondary>
      <gl-sprintf :message="__('Created %{timestamp}')">
        <template #timestamp>
          <span v-gl-tooltip :title="tooltipTitle(packageEntity.created_at)">
            {{ timeFormatted(packageEntity.created_at) }}
          </span>
        </template>
      </gl-sprintf>
    </template>

    <template v-if="!disableDelete" #right-action>
      <gl-button
        data-testid="action-delete"
        icon="remove"
        category="primary"
        variant="danger"
        :title="s__('PackageRegistry|Remove package')"
        :aria-label="s__('PackageRegistry|Remove package')"
        :disabled="!packageEntity._links.delete_api_path"
        @click="$emit('packageToDelete', packageEntity)"
      />
    </template>
  </list-item>
</template>
