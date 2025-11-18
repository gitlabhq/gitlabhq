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
          'Open the GitLab Duo AI assistant panel from anywhere in GitLab. Ask questions, request code help, or get guidance without interrupting your workflow.',
        )
      }}
    </p>
    <illustration />
  </div>
</template>
