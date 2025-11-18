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
          'GitLab now has a sleek panel-based layout. Find what you need faster with centered search and all your work items conveniently positioned in the upper right.',
        )
      }}
    </p>

    <illustration />
  </div>
</template>
