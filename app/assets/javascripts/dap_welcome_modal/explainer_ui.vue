<script>
import Illustration from './illustrations/explainer_ui_illustration.vue';

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
          "We've improved the GitLab user experience with a more modern, intuitive interface built on a new panel-based layout.",
        )
      }}
    </p>

    <illustration />
  </div>
</template>
