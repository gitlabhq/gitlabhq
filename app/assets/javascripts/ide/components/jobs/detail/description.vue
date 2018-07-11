<script>
import Icon from '../../../../vue_shared/components/icon.vue';
import CiIcon from '../../../../vue_shared/components/ci_icon.vue';

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
  <div class="d-flex align-items-center">
    <ci-icon
      :status="job.status"
      :borderless="true"
      :size="24"
      class="d-flex"
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
          :size="12"
          name="external-link"
        />
      </a>
    </span>
  </div>
</template>
