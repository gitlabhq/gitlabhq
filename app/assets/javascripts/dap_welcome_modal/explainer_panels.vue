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
          'Stay in your workflow with contextual panels. Select an issue to view its details right alongside your list, so you can quickly review, edit, and move on to the next task.',
        )
      }}
    </p>
    <illustration />
  </div>
</template>
