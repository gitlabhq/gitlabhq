<script>
import { GlLink } from '@gitlab/ui';
/**
 * Renders Unmet Prerequisites block for job's view.
 */
export default {
  components: {
    GlLink,
  },
  props: {
    helpPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="bs-callout bs-callout-danger">
    <p class="js-failed-unmet-prerequisites gl-mb-0">
      {{
        s__(`Job|This job failed because the necessary resources were not successfully created.`)
      }}

      <gl-link :href="helpPath" class="js-help-path">
        <strong> {{ __('More information') }} </strong>
      </gl-link>
    </p>
  </div>
</template>
