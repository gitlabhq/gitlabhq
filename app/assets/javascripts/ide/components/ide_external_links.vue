<script>
import icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    icon,
  },
  props: {
    projectUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    goBackUrl() {
      return document.referrer || this.projectUrl;
    },
  },
};
</script>

<template>
  <a
    :href="goBackUrl"
    class="ide-sidebar-link"
    :aria-label="s__('IDE|Go back')"
    v-once
  >
    <icon
      :size="16"
      name="go-back"
    />
  </a>
</template>
