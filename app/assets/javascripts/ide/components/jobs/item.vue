<script>
import CiIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  components: {
    CiIcon,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <ci-icon :status="job.status" />
    {{ job.name }}
    <a
      :href="job.build_path"
      target="_blank"
    >#{{ job.id }}</a>
  </div>
</template>
