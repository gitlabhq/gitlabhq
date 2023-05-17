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
import { __ } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import {
  DELETE_PACKAGE_TEXT,
  ERRORED_PACKAGE_TEXT,
  ERROR_PUBLISHING,
  PACKAGE_ERROR_STATUS,
  PACKAGE_DEFAULT_STATUS,
  WARNING_TEXT,
} from '~/packages_and_registries/package_registry/constants';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import PackagePath from '~/packages_and_registries/shared/components/package_path.vue';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMethod from '~/packages_and_registries/package_registry/components/list/publish_method.vue';
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
    containsWebPathLink() {
      return Boolean(this.packageEntity?._links?.webPath);
    },
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
    errorPackageStyle() {
      return {
        'gl-text-red-500': this.errorStatusRow,
        'gl-font-weight-normal': this.errorStatusRow,
      };
    },
  },
  i18n: {
    erroredPackageText: ERRORED_PACKAGE_TEXT,
    createdAt: __('Created %{timestamp}'),
    deletePackage: DELETE_PACKAGE_TEXT,
    errorPublishing: ERROR_PUBLISHING,
    warning: WARNING_TEXT,
    moreActions: __('More actions'),
  },
};
</script>

<template>
  <list-item data-testid="package-row" :selected="selected" v-bind="$attrs">
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
          v-if="containsWebPathLink"
          :class="errorPackageStyle"
          class="gl-text-body gl-min-w-0"
          data-testid="details-link"
          data-qa-selector="package_link"
          :to="{ name: 'details', params: { id: packageId } }"
        >
          <gl-truncate :text="packageEntity.name" />
        </router-link>
        <gl-truncate v-else :text="packageEntity.name" />

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
      <div
        v-if="!errorStatusRow"
        class="gl-display-flex gl-align-items-center"
        data-testid="left-secondary-infos"
      >
        <gl-truncate
          class="gl-max-w-15 gl-md-max-w-26"
          :text="packageEntity.version"
          :with-tooltip="true"
        />

        <div v-if="pipelineUser" class="gl-display-none gl-sm-display-flex gl-ml-2">
          <gl-sprintf :message="s__('PackageRegistry|published by %{author}')">
            <template #author>{{ pipelineUser }}</template>
          </gl-sprintf>
        </div>

        <span class="gl-ml-2" data-testid="package-type">&middot; {{ packageType }}</span>

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
