<script>
import { GlButton, GlLink, GlSprintf, GlTooltipDirective, GlTruncate } from '@gitlab/ui';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { getPackageTypeLabel } from '../utils';
import PackagePath from './package_path.vue';
import PackageTags from './package_tags.vue';
import PublishMethod from './publish_method.vue';

export default {
  name: 'PackageListRow',
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    GlTruncate,
    PackageTags,
    PackagePath,
    PublishMethod,
    ListItem,
    PackageIconAndName: () =>
      import(/* webpackChunkName: 'package_registry_components' */ './package_icon_and_name.vue'),
    InfrastructureIconAndName: () =>
      import(
        /* webpackChunkName: 'infrastructure_registry_components' */ '~/packages_and_registries/infrastructure_registry/components/infrastructure_icon_and_name.vue'
      ),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  inject: {
    iconComponent: {
      from: 'iconComponent',
      default: 'PackageIconAndName',
    },
  },
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
  <list-item data-qa-selector="package_row">
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center gl-mr-3 gl-min-w-0">
        <gl-link
          :href="packageLink"
          class="gl-text-body gl-min-w-0"
          data-qa-selector="package_link"
        >
          <gl-truncate :text="packageEntity.name" />
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

        <div v-if="hasPipeline" class="gl-display-none gl-sm-display-flex gl-ml-2">
          <gl-sprintf :message="s__('PackageRegistry|published by %{author}')">
            <template #author>{{ packageEntity.pipeline.user.name }}</template>
          </gl-sprintf>
        </div>

        <component :is="iconComponent" v-if="showPackageType">
          {{ packageType }}
        </component>

        <package-path v-if="hasProjectLink" :path="packageEntity.project_path" />
      </div>
    </template>

    <template #right-primary>
      <publish-method :package-entity="packageEntity" :is-group="isGroup" />
    </template>

    <template #right-secondary>
      <span>
        <gl-sprintf :message="__('Created %{timestamp}')">
          <template #timestamp>
            <span v-gl-tooltip :title="tooltipTitle(packageEntity.created_at)">
              {{ timeFormatted(packageEntity.created_at) }}
            </span>
          </template>
        </gl-sprintf>
      </span>
    </template>

    <template v-if="!disableDelete" #right-action>
      <gl-button
        data-testid="action-delete"
        icon="remove"
        category="secondary"
        variant="danger"
        :title="s__('PackageRegistry|Remove package')"
        :aria-label="s__('PackageRegistry|Remove package')"
        :disabled="!packageEntity._links.delete_api_path"
        @click="$emit('packageToDelete', packageEntity)"
      />
    </template>
  </list-item>
</template>
