<script>
import { GlLink } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { ciStatusToIcon } from './utils/ci';

export default {
  name: 'CiItemPresenter',
  components: {
    GlLink,
    CiIcon,
  },
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  computed: {
    href() {
      // webPath for jobs, path for pipelines
      return this.data.webPath || this.data.path;
    },
    status() {
      return ciStatusToIcon(this.data.status);
    },
    displayId() {
      return this.data.id ? `#${this.data.id}` : null;
    },
    label() {
      if (this.displayId && this.data.name) return `${this.displayId}: ${this.data.name}`;
      return this.data.name || this.displayId;
    },
  },
};
</script>
<template>
  <span class="gl-inline-flex gl-items-center gl-gap-2">
    <ci-icon v-if="status" :status="status" :use-link="false" :show-tooltip="true" />
    <gl-link v-if="href" :href="href">{{ label }}</gl-link>
    <span v-else>{{ label }}</span>
  </span>
</template>
