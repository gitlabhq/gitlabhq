<script>
import { GlLink, GlSprintf, GlTruncate } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMethod from '~/packages_and_registries/shared/components/publish_method.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { PACKAGE_DEFAULT_STATUS } from '../../constants';

export default {
  name: 'PackageVersionRow',
  components: {
    GlLink,
    GlSprintf,
    GlTruncate,
    PackageTags,
    PublishMethod,
    ListItem,
    TimeAgoTooltip,
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  computed: {
    containsWebPathLink() {
      return Boolean(this.packageEntity?._links?.webPath);
    },
    packageLink() {
      return `${getIdFromGraphQLId(this.packageEntity.id)}`;
    },
    disabledRow() {
      return this.packageEntity.status && this.packageEntity.status !== PACKAGE_DEFAULT_STATUS;
    },
  },
};
</script>

<template>
  <list-item :disabled="disabledRow">
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center gl-mr-3 gl-min-w-0">
        <gl-link
          v-if="containsWebPathLink"
          class="gl-text-body gl-min-w-0"
          :disabled="disabledRow"
          :href="packageLink"
        >
          <gl-truncate :text="packageEntity.name" />
        </gl-link>
        <gl-truncate v-else :text="packageEntity.name" />

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
      {{ packageEntity.version }}
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
  </list-item>
</template>
