<script>
import { GlIcon, GlSprintf } from '@gitlab/ui';
import { MANIFEST_PENDING_DESTRUCTION_STATUS } from '~/packages_and_registries/dependency_proxy/constants';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';

export default {
  name: 'ManifestRow',
  components: {
    GlIcon,
    GlSprintf,
    ListItem,
    TimeagoTooltip,
  },
  props: {
    manifest: {
      type: Object,
      required: true,
    },
  },
  computed: {
    name() {
      return this.manifest?.imageName.split(':')[0];
    },
    version() {
      return this.manifest?.imageName.split(':')[1];
    },
    isErrorStatus() {
      return this.manifest?.status === MANIFEST_PENDING_DESTRUCTION_STATUS;
    },
    disabledRowStyle() {
      return this.isErrorStatus ? 'gl-font-weight-normal gl-text-gray-500' : '';
    },
  },
  i18n: {
    cachedAgoMessage: s__('DependencyProxy|Cached %{time}'),
    scheduledForDeletion: s__('DependencyProxy|Scheduled for deletion'),
  },
};
</script>

<template>
  <list-item :disabled="isErrorStatus">
    <template #left-primary>
      <span :class="disabledRowStyle">{{ name }}</span>
    </template>
    <template #left-secondary>
      {{ version }}
      <span v-if="isErrorStatus" class="gl-ml-4" data-testid="status"
        ><gl-icon name="clock" /> {{ $options.i18n.scheduledForDeletion }}</span
      >
    </template>
    <template #right-primary> &nbsp; </template>
    <template #right-secondary>
      <timeago-tooltip :time="manifest.createdAt" data-testid="cached-message">
        <template #default="{ timeAgo }">
          <gl-sprintf :message="$options.i18n.cachedAgoMessage">
            <template #time>{{ timeAgo }}</template>
          </gl-sprintf>
        </template>
      </timeago-tooltip>
    </template>
  </list-item>
</template>
