<script>
import Illustration from './illustrations/explainer_sidebar_illustration.vue';

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
          'The left navigation menu now collapses and expands to provide flexible sidebar management.',
        )
      }}
    </p>
    <illustration />
  </div>
</template>
