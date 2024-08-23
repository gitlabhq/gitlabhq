<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

export default {
  components: {
    GlIcon,
    CiIcon,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    jobId() {
      return `#${this.job.id}`;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <ci-icon :status="job.status" class="gl-border gl-z-1 gl-inline-flex gl-items-center" />
    <span class="gl-ml-3">
      {{ job.name }}
      <a
        v-if="job.path"
        :href="job.path"
        target="_blank"
        class="ide-external-link gl-relative"
        data-testid="description-detail-link"
      >
        {{ jobId }} <gl-icon :size="12" name="external-link" />
      </a>
    </span>
  </div>
</template>
