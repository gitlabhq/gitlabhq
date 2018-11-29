<script>
import { GlLink } from '@gitlab/ui';
/**
 * Renders Stuck Runners block for job's view.
 */
export default {
  components: {
    GlLink,
  },
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
    <p v-if="tags.length" class="js-stuck-with-tags append-bottom-0">
      {{
        s__(`This job is stuck because you don't have
  any active runners online with any of these tags assigned to them:`)
      }}
      <span v-for="(tag, index) in tags" :key="index" class="badge badge-primary append-right-4">
        {{ tag }}
      </span>
    </p>
    <p v-else-if="hasNoRunnersForProject" class="js-stuck-no-runners append-bottom-0">
      {{
        s__(`Job|This job is stuck because the project
  doesn't have any runners online assigned to it.`)
      }}
    </p>
    <p v-else class="js-stuck-no-active-runner append-bottom-0">
      {{
        s__(`This job is stuck because you don't
  have any active runners that can run this job.`)
      }}
    </p>

    {{ __('Go to') }}
    <gl-link v-if="runnersPath" :href="runnersPath" class="js-runners-path">
      {{ __('Runners page') }}
    </gl-link>
  </div>
</template>
