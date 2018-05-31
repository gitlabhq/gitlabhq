<script>
import Icon from '../../../vue_shared/components/icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  components: {
    Icon,
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
  <div class="ide-job-item">
    <ci-icon
      :status="job.status"
      :borderless="true"
      :size="24"
    />
    <span class="prepend-left-8">
      {{ job.name }}
      <a
        :href="job.path"
        target="_blank"
        class="ide-external-link"
      >
        {{ jobId }}
        <icon
          name="external-link"
          :size="12"
        />
      </a>
    </span>
    <button
      class="btn btn-default btn-sm"
      @click="() => { $store.state.pipelines.detailJob = job; $store.dispatch('setRightPane', 'jobs-detail') }"
    >
      {{ __('View log') }}
    </button>
  </div>
</template>

<style scoped>
.btn {
  margin-left: auto;
}
</style>
