<script>
export default {
  props: {
    quotaUsed: {
      type: Number,
      required: true,
    },
    quotaLimit: {
      type: Number,
      required: true,
    },
    runnersPath: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>
<template>
  <div class="bs-callout bs-callout-warning">
    <p>
      {{ s__("Runners|You have used all your shared Runners pipeline minutes.") }}
      {{ quotaUsed }} of {{ quotaLimit }}

      <template v-if="runnersPath">
        {{ __("For more information, go to the ") }}
        <a :href="runnersPath">
          {{ __("Runners page.") }}
        </a>
      </template>
    </p>
  </div>
</template>
