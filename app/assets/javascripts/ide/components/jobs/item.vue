<script>
import JobDescription from './detail/description.vue';

export default {
  components: {
    JobDescription,
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
    <job-description
      :job="job"
      class="append-right-default"
    />
    <div class="ml-auto align-self-center">
      <button
        v-if="job.started"
        type="button"
        class="btn btn-default btn-sm"
        @click="clickViewLog"
      >
        {{ __('View log') }}
      </button>
    </div>
  </div>
</template>
