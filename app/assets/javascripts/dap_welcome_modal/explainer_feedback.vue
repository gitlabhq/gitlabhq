<script>
import Illustration from './illustrations/explainer_feedback_illustration.vue';

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
          'Please share your feedback — our engineers are listening. This toggle is temporary, and the panel UI will soon become the default view.',
        )
      }}
    </p>

    <illustration />
  </div>
</template>
