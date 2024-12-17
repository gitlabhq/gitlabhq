<script>
import { GlLink, GlSprintf, GlTruncate } from '@gitlab/ui';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'MlCandidateListRow',
  components: {
    ListItem,
    GlLink,
    GlTruncate,
    GlSprintf,
    TimeAgoTooltip,
  },
  props: {
    candidate: {
      type: Object,
      required: true,
    },
  },
  computed: {
    pathToDetails() {
      return this.candidate._links?.showPath;
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs">
    <template #left-primary>
      <div class="gl-flex gl-items-center">
        <gl-link class="gl-text-default" :href="pathToDetails">
          <gl-truncate :text="candidate.name" />
        </gl-link>
      </div>
    </template>

    <template #left-secondary>
      <span>
        <gl-sprintf :message="__('Created %{timestamp}')">
          <template #timestamp>
            <time-ago-tooltip :time="candidate.createdAt" />
          </template>
        </gl-sprintf>
      </span>
    </template>
  </list-item>
</template>
