<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormCheckbox,
  GlIcon,
  GlSprintf,
  GlTruncate,
  GlLink,
  GlBadge,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
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
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMethod from '~/packages_and_registries/package_registry/components/list/publish_method.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'PackageListRow',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlFormCheckbox,
    GlIcon,
    GlSprintf,
    GlTruncate,
    GlLink,
    GlBadge,
    PackageTags,
    PublishMethod,
    ListItem,
    TimeagoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
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
      return this.packageEntity.project.name;
    },
    projectLink() {
      return this.packageEntity.project.webUrl;
    },
    pipelineUser() {
      return this.pipeline?.user?.name;
    },
    publishedMessage() {
      if (this.isGroupPage) {
        if (this.pipelineUser) {
          return s__(`PackageRegistry|Published to %{projectName} by %{author}, %{date}`);
        }
        return s__(`PackageRegistry|Published to %{projectName}, %{date}`);
      }

      if (this.pipelineUser) {
        return s__(`PackageRegistry|Published by %{author}, %{date}`);
      }

      return s__(`PackageRegistry|Published %{date}`);
    },
    errorStatusRow() {
      return this.packageEntity.status === PACKAGE_ERROR_STATUS;
    },
    errorStatusMessage() {
      return this.packageEntity.statusMessage
        ? this.packageEntity.statusMessage
        : ERRORED_PACKAGE_TEXT;
    },
    showTags() {
      return Boolean(this.packageEntity.tags?.nodes?.length);
    },
    showBadgeProtected() {
      return (
        Boolean(this.glFeatures.packagesProtectedPackages) &&
        Boolean(this.packageEntity.packageProtectionRuleExists)
      );
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
      <div class="gl-display-flex gl-align-items-center gl-mr-3 gl-min-w-0">
        <router-link
          v-if="containsWebPathLink"
          :class="errorPackageStyle"
          class="gl-text-body gl-min-w-0"
          data-testid="details-link"
          :to="{ name: 'details', params: { id: packageId } }"
        >
          <gl-truncate :text="packageEntity.name" />
        </router-link>
        <gl-truncate v-else :class="errorPackageStyle" :text="packageEntity.name" />

        <package-tags
          v-if="showTags"
          class="gl-ml-3"
          :tags="packageEntity.tags.nodes"
          hide-label
          :tag-display-limit="1"
        />

        <gl-badge
          v-if="showBadgeProtected"
          v-gl-tooltip="{ title: $options.i18n.badgeProtectedTooltipText }"
          class="gl-ml-3"
          icon-size="sm"
          size="sm"
          variant="neutral"
          >{{ __('protected') }}</gl-badge
        >
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
        <span class="gl-ml-2" data-testid="package-type">&middot; {{ packageType }}</span>
      </div>
      <div v-else class="gl-text-red-500">
        <gl-icon name="warning" :aria-label="$options.i18n.warning" data-testid="warning-icon" />
        <span data-testid="error-message"
          >{{ $options.i18n.errorPublishing }} &middot; {{ errorStatusMessage }}</span
        >
      </div>
    </template>

    <template #right-primary>
      <publish-method :pipeline="pipeline" />
    </template>

    <template #right-secondary>
      <span data-testid="right-secondary">
        <gl-sprintf :message="publishedMessage">
          <template v-if="isGroupPage" #projectName>
            <gl-link
              data-testid="root-link"
              class="gl-text-decoration-underline"
              :href="projectLink"
              >{{ projectName }}</gl-link
            >
          </template>
          <template #date>
            <timeago-tooltip :time="packageEntity.createdAt" />
          </template>
          <template v-if="pipelineUser" #author>{{ pipelineUser }}</template>
        </gl-sprintf>
      </span>
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
