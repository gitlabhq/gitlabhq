<script>
import { GlButton, GlSprintf, GlTooltipDirective, GlTruncate } from '@gitlab/ui';
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
    GlButton,
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
    showWarningIcon() {
      return this.packageEntity.status === PACKAGE_ERROR_STATUS;
    },
    showTags() {
      return Boolean(this.packageEntity.tags?.nodes?.length);
    },
    disabledRow() {
      return this.packageEntity.status && this.packageEntity.status !== PACKAGE_DEFAULT_STATUS;
    },
    routerLinkEvent() {
      return this.disabledRow ? '' : 'click';
    },
  },
  i18n: {
    erroredPackageText: s__('PackageRegistry|Invalid Package: failed metadata extraction'),
    createdAt: __('Created %{timestamp}'),
  },
};
</script>

<template>
  <list-item data-qa-selector="package_row" :disabled="disabledRow">
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center gl-mr-3 gl-min-w-0">
        <router-link
          class="gl-text-body gl-min-w-0"
          data-testid="details-link"
          data-qa-selector="package_link"
          :event="routerLinkEvent"
          :to="{ name: 'details', params: { id: packageId } }"
        >
          <gl-truncate :text="packageEntity.name" />
        </router-link>

        <gl-button
          v-if="showWarningIcon"
          v-gl-tooltip="{ title: $options.i18n.erroredPackageText }"
          class="gl-hover-bg-transparent!"
          icon="warning"
          category="tertiary"
          data-testid="warning-icon"
          :aria-label="__('Warning')"
        />

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
      <div class="gl-display-flex" data-testid="left-secondary-infos">
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
          :disabled="disabledRow"
        />
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

    <template v-if="!disabledRow" #right-action>
      <gl-button
        data-testid="action-delete"
        icon="remove"
        category="secondary"
        variant="danger"
        :title="s__('PackageRegistry|Remove package')"
        :aria-label="s__('PackageRegistry|Remove package')"
        @click="$emit('packageToDelete', packageEntity)"
      />
    </template>
  </list-item>
</template>
