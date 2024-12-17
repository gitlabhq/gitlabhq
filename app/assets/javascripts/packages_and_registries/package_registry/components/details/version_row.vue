<script>
import {
  GlDisclosureDropdown,
  GlFormCheckbox,
  GlIcon,
  GlLink,
  GlTooltipDirective,
  GlTruncate,
} from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMessage from '~/packages_and_registries/shared/components/publish_message.vue';
import PublishMethod from '~/packages_and_registries/shared/components/publish_method.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
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
    GlTruncate,
    PackageTags,
    PublishMessage,
    PublishMethod,
    ListItem,
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
        'gl-font-normal': this.errorStatusRow,
      };
    },
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.deletePackage,
          action: () => this.$emit('delete'),
          extraAttrs: {
            class: '!gl-text-red-500',
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
      <div class="gl-mr-5 gl-flex gl-min-w-0 gl-items-center gl-gap-3" data-testid="package-name">
        <gl-link
          v-if="containsWebPathLink"
          class="gl-min-w-0 gl-break-all gl-text-default"
          :class="errorPackageStyle"
          :href="packageLink"
        >
          {{ packageEntity.name }}
        </gl-link>
        <span v-else :class="errorPackageStyle">
          {{ packageEntity.name }}
        </span>

        <div
          v-if="packageEntity.tags.nodes && packageEntity.tags.nodes.length"
          class="gl-flex gl-gap-2"
        >
          <package-tags :tags="packageEntity.tags.nodes" hide-label :tag-display-limit="1" />
        </div>
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
        class="gl-max-w-15 md:gl-max-w-26"
        :text="packageEntity.version"
        :with-tooltip="true"
      />
    </template>

    <template #right-primary>
      <publish-method :package-entity="packageEntity" />
    </template>

    <template #right-secondary>
      <publish-message :publish-date="packageEntity.createdAt" />
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
