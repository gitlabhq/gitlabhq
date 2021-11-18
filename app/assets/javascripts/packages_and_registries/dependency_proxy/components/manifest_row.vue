<script>
import { GlSprintf } from '@gitlab/ui';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';

export default {
  name: 'ManifestRow',
  components: {
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
  },
  i18n: {
    cachedAgoMessage: s__('DependencyProxy|Cached %{time}'),
  },
};
</script>

<template>
  <list-item>
    <template #left-primary> {{ name }} </template>
    <template #left-secondary> {{ version }} </template>
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
