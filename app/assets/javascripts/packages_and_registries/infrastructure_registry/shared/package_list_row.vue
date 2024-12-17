<script>
import { GlButton, GlLink, GlSprintf, GlTooltipDirective, GlTruncate } from '@gitlab/ui';
import { s__ } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import {
  PACKAGE_ERROR_STATUS,
  PACKAGE_DEFAULT_STATUS,
} from '~/packages_and_registries/shared/constants';
import PackagePath from '~/packages_and_registries/shared/components/package_path.vue';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMethod from '~/packages_and_registries/shared/components/publish_method.vue';
import InfrastructureIconAndName from '~/packages_and_registries/infrastructure_registry/shared/infrastructure_icon_and_name.vue';

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
    InfrastructureIconAndName,
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
    hasPipeline() {
      return Boolean(this.packageEntity.pipeline?.user?.name);
    },
    hasProjectLink() {
      return Boolean(this.packageEntity.project_path);
    },
    showWarningIcon() {
      return this.packageEntity.status === PACKAGE_ERROR_STATUS;
    },
    disabledRow() {
      return this.packageEntity.status && this.packageEntity.status !== PACKAGE_DEFAULT_STATUS;
    },
    disabledDeleteButton() {
      return this.disabledRow || !this.packageEntity._links.delete_api_path;
    },
  },
  i18n: {
    erroredPackageText: s__('PackageRegistry|Invalid Package: failed metadata extraction'),
  },
};
</script>

<template>
  <list-item data-testid="package-row" :disabled="disabledRow">
    <template #left-primary>
      <div class="gl-mr-3 gl-flex gl-min-w-0 gl-items-center">
        <gl-link
          :href="packageLink"
          class="gl-min-w-0 gl-text-default"
          data-testid="details-link"
          :disabled="disabledRow"
        >
          <gl-truncate :text="packageEntity.name" />
        </gl-link>

        <gl-button
          v-if="showWarningIcon"
          v-gl-tooltip="{ title: $options.i18n.erroredPackageText }"
          class="hover:!gl-bg-transparent"
          icon="warning"
          category="tertiary"
          data-testid="warning-icon"
          :aria-label="__('Warning')"
        />

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
      <div class="gl-flex">
        <span>{{ packageEntity.version }}</span>

        <div v-if="hasPipeline" class="sm:g-flex gl-ml-2 gl-hidden">
          <gl-sprintf :message="s__('PackageRegistry|published by %{author}')">
            <template #author>{{ packageEntity.pipeline.user.name }}</template>
          </gl-sprintf>
        </div>

        <infrastructure-icon-and-name v-if="showPackageType" />

        <package-path
          v-if="hasProjectLink"
          :path="packageEntity.project_path"
          :disabled="disabledRow"
        />
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
        :disabled="disabledDeleteButton"
        @click="$emit('packageToDelete', packageEntity)"
      />
    </template>
  </list-item>
</template>
