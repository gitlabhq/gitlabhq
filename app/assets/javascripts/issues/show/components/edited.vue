<script>
import { GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    TimeAgoTooltip,
    GlSprintf,
  },
  props: {
    updatedAt: {
      type: String,
      required: false,
      default: '',
    },
    updatedByName: {
      type: String,
      required: false,
      default: '',
    },
    updatedByPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasUpdatedBy() {
      return this.updatedByName && this.updatedByPath;
    },
  },
};
</script>

<template>
  <small class="edited-text js-issue-widgets">
    <gl-sprintf v-if="!hasUpdatedBy" :message="__('Edited %{timeago}')">
      <template #timeago>
        <time-ago-tooltip :time="updatedAt" tooltip-placement="bottom" />
      </template>
    </gl-sprintf>
    <gl-sprintf v-else-if="!updatedAt" :message="__('Edited by %{author}')">
      <template #author>
        <a :href="updatedByPath" class="author-link gl-hover-text-decoration-underline">
          <span>{{ updatedByName }}</span>
        </a>
      </template>
    </gl-sprintf>
    <gl-sprintf v-else :message="__('Edited %{timeago} by %{author}')">
      <template #timeago>
        <time-ago-tooltip :time="updatedAt" tooltip-placement="bottom" />
      </template>
      <template #author>
        <a :href="updatedByPath" class="author-link gl-hover-text-decoration-underline">
          <span>{{ updatedByName }}</span>
        </a>
      </template>
    </gl-sprintf>
  </small>
</template>
