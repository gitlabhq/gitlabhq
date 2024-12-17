<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormCheckbox,
  GlIcon,
  GlTruncate,
} from '@gitlab/ui';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import { s__, __ } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import {
  DELETE_PACKAGE_TEXT,
  ERRORED_PACKAGE_TEXT,
  ERROR_PUBLISHING,
  PACKAGE_ERROR_STATUS,
  PACKAGE_DEFAULT_STATUS,
  PACKAGE_DEPRECATED_STATUS,
  WARNING_TEXT,
} from '~/packages_and_registries/package_registry/constants';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMessage from '~/packages_and_registries/shared/components/publish_message.vue';
import PublishMethod from '~/packages_and_registries/package_registry/components/list/publish_method.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  name: 'PackageListRow',
  components: {
    GlBadge,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlFormCheckbox,
    GlIcon,
    GlTruncate,
    PackageTags,
    PublishMessage,
    PublishMethod,
    ListItem,
    ProtectedBadge,
  },
  inject: ['isGroupPage', 'canDeletePackages'],
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
    projectName() {
      return this.isGroupPage ? this.packageEntity.project?.name : '';
    },
    projectUrl() {
      return this.isGroupPage ? this.packageEntity.project?.webUrl : '';
    },
    pipelineUser() {
      return this.pipeline?.user?.name;
    },
    errorStatusRow() {
      return this.packageEntity.status === PACKAGE_ERROR_STATUS;
    },
    errorStatusMessage() {
      return this.packageEntity.statusMessage
        ? this.packageEntity.statusMessage
        : ERRORED_PACKAGE_TEXT;
    },
    showBadges() {
      return this.showTags || this.showBadgeProtected || this.showDeprecatedBadge;
    },
    showTags() {
      return Boolean(this.packageEntity.tags?.nodes?.length);
    },
    showBadgeProtected() {
      return this.packageEntity.protectionRuleExists;
    },
    showDeprecatedBadge() {
      return this.packageEntity.status === PACKAGE_DEPRECATED_STATUS;
    },
    nonDefaultRow() {
      return this.packageEntity.status && this.packageEntity.status !== PACKAGE_DEFAULT_STATUS;
    },
    errorPackageStyle() {
      return {
        'gl-text-red-500': this.errorStatusRow,
        'gl-font-normal': this.errorStatusRow,
      };
    },
  },
  i18n: {
    createdAt: __('Created %{timestamp}'),
    deletePackage: DELETE_PACKAGE_TEXT,
    errorPublishing: ERROR_PUBLISHING,
    warning: WARNING_TEXT,
    moreActions: __('More actions'),
    badgeProtectedTooltipText: s__('PackageRegistry|A protection rule exists for this package.'),
  },
};
</script>

<template>
  <list-item data-testid="package-row" :selected="selected" v-bind="$attrs">
    <template #left-action>
      <gl-form-checkbox
        v-if="canDeletePackages"
        class="gl-m-0"
        :checked="selected"
        @change="$emit('select')"
      />
    </template>
    <template #left-primary>
      <div class="gl-mr-5 gl-flex gl-min-w-0 gl-items-center gl-gap-3" data-testid="package-name">
        <router-link
          v-if="containsWebPathLink"
          :class="errorPackageStyle"
          class="gl-min-w-0 gl-break-all gl-text-default"
          data-testid="details-link"
          :to="{ name: 'details', params: { id: packageId } }"
        >
          {{ packageEntity.name }}
        </router-link>
        <span v-else :class="errorPackageStyle">
          {{ packageEntity.name }}
        </span>

        <div v-if="showBadges" class="gl-flex gl-gap-3">
          <package-tags
            v-if="showTags"
            :tags="packageEntity.tags.nodes"
            hide-label
            :tag-display-limit="1"
          />

          <protected-badge
            v-if="showBadgeProtected"
            :tooltip-text="$options.i18n.badgeProtectedTooltipText"
          />

          <gl-badge v-if="showDeprecatedBadge" variant="warning">
            {{ s__('PackageRegistry|deprecated') }}
          </gl-badge>
        </div>
      </div>
    </template>
    <template #left-secondary>
      <div
        v-if="!errorStatusRow"
        class="gl-flex gl-items-center"
        data-testid="left-secondary-infos"
      >
        <gl-truncate
          class="gl-max-w-15 md:gl-max-w-26"
          :text="packageEntity.version"
          :with-tooltip="true"
        />
        <span class="gl-ml-2" data-testid="package-type">&middot; {{ packageType }}</span>
      </div>
      <div v-else class="gl-text-red-500">
        <gl-icon name="warning" :aria-label="$options.i18n.warning" data-testid="warning-icon" />
        <span data-testid="error-message"
          >{{ $options.i18n.errorPublishing }} &middot; {{ errorStatusMessage }}</span
        >
      </div>
    </template>

    <template v-if="!errorStatusRow" #right-primary>
      <publish-method :pipeline="pipeline" />
    </template>

    <template v-if="!errorStatusRow" #right-secondary>
      <publish-message
        :author="pipelineUser"
        :project-name="projectName"
        :project-url="projectUrl"
        :publish-date="packageEntity.createdAt"
      />
    </template>

    <template v-if="packageEntity.userPermissions.destroyPackage" #right-action>
      <gl-disclosure-dropdown
        category="tertiary"
        data-testid="delete-dropdown"
        icon="ellipsis_v"
        :toggle-text="$options.i18n.moreActions"
        text-sr-only
        no-caret
      >
        <gl-disclosure-dropdown-item data-testid="action-delete" @action="$emit('delete')">
          <template #list-item>
            <span class="gl-text-red-500">
              {{ $options.i18n.deletePackage }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown>
    </template>
  </list-item>
</template>
