<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton } from '@gitlab/ui';
import JobDescription from './detail/description.vue';

export default {
  components: {
    JobDescription,
    GlButton,
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
  methods: {
    clickViewLog() {
      this.$emit('clickViewLog', this.job);
    },
  },
};
</script>

<template>
  <div class="ide-job-item">
    <job-description :job="job" class="gl-mr-3" />
    <div class="ml-auto align-self-center">
      <gl-button v-if="job.started" category="secondary" size="small" @click="clickViewLog">
        {{ __('View log') }}
      </gl-button>
    </div>
  </div>
</template>
