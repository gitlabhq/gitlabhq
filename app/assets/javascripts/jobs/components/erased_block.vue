<script>
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    TimeagoTooltip,
  },
  props: {
    erasedByUser: {
      type: Boolean,
      required: true,
    },
    username: {
      type: String,
      required: false,
      default: null,
    },
    linkToUser: {
      type: String,
      required: false,
      default: null,
    },
    erasedAt: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="prepend-top-default js-build-erased">
    <div class="erased alert alert-warning">
      <template v-if="erasedByUser">
        {{ s__("Job|Job has been erased by") }}

        <a
          :href="linkToUser"
        >
          {{ username }}
        </a>

        <timeago-tooltip
          :time="erasedAt"
        />

      </template>
      <template v-else>
        {{ s__("Job|Job has been erased") }}
        <timeago-tooltip
          :time="erasedAt"
        />
      </template>
    </div>
  </div>
</template>
