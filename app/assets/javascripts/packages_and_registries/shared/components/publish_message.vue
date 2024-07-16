<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';

export default {
  components: {
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
  },
  props: {
    author: {
      type: String,
      required: false,
      default: '',
    },
    projectName: {
      type: String,
      required: false,
      default: '',
    },
    projectUrl: {
      type: String,
      required: false,
      default: '#',
    },
    publishDate: {
      type: String,
      required: true,
    },
  },
  computed: {
    publishedMessage() {
      if (this.projectName) {
        if (this.author) {
          return s__('PackageRegistry|Published to %{projectName} by %{author}, %{date}');
        }
        return s__('PackageRegistry|Published to %{projectName}, %{date}');
      }

      if (this.author) {
        return s__('PackageRegistry|Published by %{author}, %{date}');
      }

      return s__('PackageRegistry|Published %{date}');
    },
  },
};
</script>

<template>
  <span>
    <gl-sprintf :message="publishedMessage">
      <template v-if="projectName" #projectName>
        <gl-link class="gl-underline" :href="projectUrl">{{ projectName }}</gl-link>
      </template>
      <template #date>
        <time-ago-tooltip :time="publishDate" />
      </template>
      <template v-if="author" #author>{{ author }}</template>
    </gl-sprintf>
  </span>
</template>
