<script>
import { GlLink, GlSprintf, GlTruncate } from '@gitlab/ui';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'MlModelVersionRow',
  components: {
    ListItem,
    GlLink,
    GlTruncate,
    GlSprintf,
    TimeAgoTooltip,
  },
  props: {
    modelVersion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    pathToDetails() {
      return this.modelVersion._links?.showPath;
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs">
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center">
        <gl-link class="gl-text-body" :href="pathToDetails">
          <gl-truncate :text="modelVersion.version" />
        </gl-link>
      </div>
    </template>

    <template #left-secondary>
      <span>
        <gl-sprintf :message="__('Created %{timestamp}')">
          <template #timestamp>
            <time-ago-tooltip :time="modelVersion.createdAt" />
          </template>
        </gl-sprintf>
      </span>
    </template>
  </list-item>
</template>
