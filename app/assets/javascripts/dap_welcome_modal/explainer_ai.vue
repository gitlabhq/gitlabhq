<script>
import Illustration from './illustrations/explainer_ai_illustration.vue';

export default {
  components: {
    Illustration,
  },
};
</script>

<template>
  <div class="slide">
    <p class="gl-mb-7">
      {{
        __(
          'If you enabled Duo, you can open the GitLab Duo panel on the right side as an on-demand assistant. There, you can ask agents contextual questions and instructions from anywhere in the GitLab experience.',
        )
      }}
    </p>
    <illustration />
  </div>
</template>
