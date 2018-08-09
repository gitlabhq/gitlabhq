<script>
/**
 * Renders Stuck Runners block for job's view.
 */
export default {
  props: {
    hasNoRunnersForProject: {
      type: Boolean,
      required: true,
    },
    tags: {
      type: Array,
      required: false,
      default: () => [],
    },
    runnersPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="bs-callout bs-callout-warning">
    <p
      v-if="hasNoRunnersForProject"
      class="js-stuck-no-runners"
    >
      {{ s__(`Job|This job is stuck, because the project
  doesn't have any runners online assigned to it.`) }}
    </p>
    <p
      v-else-if="tags.length"
      class="js-stuck-with-tags"
    >
      {{ s__(`This job is stuck, because you don't have
  any active runners online with any of these tags assigned to them:`) }}
      <span
        v-for="(tag, index) in tags"
        :key="index"
        class="badge badge-primary"
      >
        {{ tag }}
      </span>
    </p>
    <p
      v-else
      class="js-stuck-no-active-runner"
    >
      {{ s__(`This job is stuck, because you don't
  have any active runners that can run this job.`) }}
    </p>

    {{ __("Go to") }}
    <a
      v-if="runnersPath"
      :href="runnersPath"
      class="js-runners-path"
    >
      {{ __("Runners page") }}
    </a>
  </div>
</template>
