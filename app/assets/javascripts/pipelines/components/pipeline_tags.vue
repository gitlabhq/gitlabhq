<script>
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  components: {
    userAvatarLink,
  },
  directives: {
    tooltip,
  },
  computed: {
    user() {
      return this.pipeline.user;
    },
  },
};
</script>
<template>
  <div class="table-section section-10 hidden-xs hidden-sm">
    <div class="label-container">
      <span
        v-if="pipeline.flags.latest"
        v-tooltip
        class="js-pipeline-url-latest label label-success"
        title="Latest pipeline for this branch">
        latest
      </span>
      <span
        v-if="pipeline.flags.yaml_errors"
        v-tooltip
        class="js-pipeline-url-yaml label label-danger"
        :title="pipeline.yaml_errors">
        yaml invalid
      </span>
      <span
        v-if="pipeline.flags.stuck"
        class="js-pipeline-url-stuck label label-warning">
        stuck
      </span>
    </div>
  </div>
</template>
