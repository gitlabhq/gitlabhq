<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlFormCheckbox,
  GlIcon,
  GlSprintf,
  GlTooltipDirective,
  GlTruncate,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import {
  PACKAGE_ERROR_STATUS,
  PACKAGE_DEFAULT_STATUS,
} from '~/packages_and_registries/package_registry/constants';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import PackagePath from '~/packages_and_registries/shared/components/package_path.vue';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMethod from '~/packages_and_registries/package_registry/components/list/publish_method.vue';
import PackageIconAndName from '~/packages_and_registries/shared/components/package_icon_and_name.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'PackageListRow',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlFormCheckbox,
    GlIcon,
    GlSprintf,
    GlTruncate,
    PackageTags,
    PackagePath,
    PublishMethod,
    ListItem,
    PackageIconAndName,
    TimeagoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['isGroupPage'],
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
    selected: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    packageType() {
      return getPackageTypeLabel(this.packageEntity.packageType);
    },
    packageId() {
      return getIdFromGraphQLId(this.packageEntity.id);
    },
    pipeline() {
      return this.packageEntity?.pipelines?.nodes[0];
    },
    pipelineUser() {
      return this.pipeline?.user?.name;
    },
    errorStatusRow() {
      return this.packageEntity.status === PACKAGE_ERROR_STATUS;
    },
    showTags() {
      return Boolean(this.packageEntity.tags?.nodes?.length);
    },
    nonDefaultRow() {
      return this.packageEntity.status && this.packageEntity.status !== PACKAGE_DEFAULT_STATUS;
    },
    routerLinkEvent() {
      return this.nonDefaultRow ? '' : 'click';
    },
    errorPackageStyle() {
      return {
        'gl-text-red-500': this.errorStatusRow,
        'gl-font-weight-normal': this.errorStatusRow,
      };
    },
  },
  i18n: {
    erroredPackageText: s__('PackageRegistry|Invalid Package: failed metadata extraction'),
    createdAt: __('Created %{timestamp}'),
    deletePackage: s__('PackageRegistry|Delete package'),
    errorPublishing: s__('PackageRegistry|Error publishing'),
    warning: __('Warning'),
    moreActions: __('More actions'),
  },
};
</script>

<template>
  <list-item data-testid="package-row" v-bind="$attrs">
    <template #left-action>
      <gl-form-checkbox
        v-if="packageEntity.canDestroy"
        class="gl-m-0"
        :checked="selected"
        @change="$emit('select')"
      />
    </template>
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center gl-mr-3 gl-min-w-0">
        <router-link
          :class="errorPackageStyle"
          class="gl-text-body gl-min-w-0"
          data-testid="details-link"
          data-qa-selector="package_link"
          :event="routerLinkEvent"
          :to="{ name: 'details', params: { id: packageId } }"
        >
          <gl-truncate :text="packageEntity.name" />
        </router-link>

        <package-tags
          v-if="showTags"
          class="gl-ml-3"
          :tags="packageEntity.tags.nodes"
          hide-label
          :tag-display-limit="1"
        />
      </div>
    </template>
    <template #left-secondary>
      <div v-if="!errorStatusRow" class="gl-display-flex" data-testid="left-secondary-infos">
        <span>{{ packageEntity.version }}</span>

        <div v-if="pipelineUser" class="gl-display-none gl-sm-display-flex gl-ml-2">
          <gl-sprintf :message="s__('PackageRegistry|published by %{author}')">
            <template #author>{{ pipelineUser }}</template>
          </gl-sprintf>
        </div>

        <package-icon-and-name>
          {{ packageType }}
        </package-icon-and-name>

        <package-path
          v-if="isGroupPage"
          :path="packageEntity.project.fullPath"
          :disabled="nonDefaultRow"
        />
      </div>
      <div v-else>
        <gl-icon
          v-gl-tooltip="{ title: $options.i18n.erroredPackageText }"
          name="warning"
          class="gl-text-red-500"
          :aria-label="$options.i18n.warning"
          data-testid="warning-icon"
        />
        <span class="gl-text-red-500">{{ $options.i18n.errorPublishing }}</span>
      </div>
    </template>

    <template #right-primary>
      <publish-method :pipeline="pipeline" />
    </template>

    <template #right-secondary>
      <span data-testid="created-date">
        <gl-sprintf :message="$options.i18n.createdAt">
          <template #timestamp>
            <timeago-tooltip :time="packageEntity.createdAt" />
          </template>
        </gl-sprintf>
      </span>
    </template>

    <template v-if="packageEntity.canDestroy" #right-action>
      <gl-dropdown
        data-testid="delete-dropdown"
        icon="ellipsis_v"
        :text="$options.i18n.moreActions"
        :text-sr-only="true"
        category="tertiary"
        no-caret
      >
        <gl-dropdown-item data-testid="action-delete" variant="danger" @click="$emit('delete')">{{
          $options.i18n.deletePackage
        }}</gl-dropdown-item>
      </gl-dropdown>
    </template>
  </list-item>
</template>
