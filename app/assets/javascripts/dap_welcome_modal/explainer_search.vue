<script>
import Illustration from './illustrations/explainer_search_illustration.vue';

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
          'Other subtle usability-driven improvements include moving the global search box to the top center for improved accessibility. Global navigation elements, including your assigned issues, merge requests, to-do items, and the user icon, move to the top right.',
        )
      }}
    </p>

    <illustration />
  </div>
</template>
