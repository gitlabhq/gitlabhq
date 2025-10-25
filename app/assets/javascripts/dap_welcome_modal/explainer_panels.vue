<script>
import Illustration from './illustrations/explainer_panels_illustration.vue';

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
          'Panels present information side by side, allowing you to work more contextually. When you select an issue from the Issues page, it opens in the details panel.',
        )
      }}
    </p>
    <illustration />
  </div>
</template>
