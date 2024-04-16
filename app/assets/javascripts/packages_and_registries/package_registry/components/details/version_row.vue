<script>
import {
  GlDisclosureDropdown,
  GlFormCheckbox,
  GlIcon,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
  GlTruncate,
} from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMethod from '~/packages_and_registries/shared/components/publish_method.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  DELETE_PACKAGE_TEXT,
  ERRORED_PACKAGE_TEXT,
  ERROR_PUBLISHING,
  PACKAGE_ERROR_STATUS,
  WARNING_TEXT,
} from '../../constants';

export default {
  name: 'PackageVersionRow',
  components: {
    GlDisclosureDropdown,
    GlFormCheckbox,
    GlIcon,
    GlLink,
    GlSprintf,
    GlTruncate,
    PackageTags,
    PublishMethod,
    ListItem,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
    packageLink() {
      return `${getIdFromGraphQLId(this.packageEntity.id)}`;
    },
    errorStatusRow() {
      return this.packageEntity?.status === PACKAGE_ERROR_STATUS;
    },
    errorPackageStyle() {
      return {
        'gl-text-red-500': this.errorStatusRow,
        'gl-font-weight-normal': this.errorStatusRow,
      };
    },
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.deletePackage,
          action: () => this.$emit('delete'),
          extraAttrs: {
            class: 'gl-text-red-500!',
            'data-testid': 'action-delete',
          },
        },
      ];
    },
  },
  i18n: {
    deletePackage: DELETE_PACKAGE_TEXT,
    erroredPackageText: ERRORED_PACKAGE_TEXT,
    errorPublishing: ERROR_PUBLISHING,
    warningText: WARNING_TEXT,
  },
};
</script>

<template>
  <list-item :selected="selected" v-bind="$attrs">
    <template #left-action>
      <gl-form-checkbox
        v-if="packageEntity.userPermissions.destroyPackage"
        class="gl-m-0"
        :checked="selected"
        @change="$emit('select')"
      />
    </template>
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center gl-mr-3 gl-min-w-0">
        <gl-link
          v-if="containsWebPathLink"
          class="gl-text-body gl-min-w-0"
          :class="errorPackageStyle"
          :href="packageLink"
        >
          <gl-truncate :text="packageEntity.name" />
        </gl-link>
        <gl-truncate v-else :class="errorPackageStyle" :text="packageEntity.name" />

        <package-tags
          v-if="packageEntity.tags.nodes && packageEntity.tags.nodes.length"
          class="gl-ml-3"
          :tags="packageEntity.tags.nodes"
          hide-label
          :tag-display-limit="1"
        />
      </div>
    </template>
    <template #left-secondary>
      <div v-if="errorStatusRow" class="gl-text-red-500">
        <gl-icon
          v-gl-tooltip="{ title: $options.i18n.erroredPackageText }"
          name="warning"
          :aria-label="$options.i18n.warningText"
        />
        <span>{{ $options.i18n.errorPublishing }}</span>
      </div>
      <gl-truncate
        v-else
        class="gl-max-w-15 gl-md-max-w-26"
        :text="packageEntity.version"
        :with-tooltip="true"
      />
    </template>

    <template #right-primary>
      <publish-method :package-entity="packageEntity" />
    </template>

    <template #right-secondary>
      <span>
        <gl-sprintf :message="__('Created %{timestamp}')">
          <template #timestamp>
            <time-ago-tooltip :time="packageEntity.createdAt" />
          </template>
        </gl-sprintf>
      </span>
    </template>

    <template v-if="packageEntity.userPermissions.destroyPackage" #right-action>
      <gl-disclosure-dropdown
        data-testid="delete-dropdown"
        icon="ellipsis_v"
        :items="dropdownItems"
        :toggle-text="$options.i18n.moreActions"
        category="tertiary"
        text-sr-only
        no-caret
      />
    </template>
  </list-item>
</template>
