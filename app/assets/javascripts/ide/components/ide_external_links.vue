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
  <nav
    class="ide-external-links"
    v-once
  >
    <p>
      <a
        :href="goBackUrl"
        class="ide-sidebar-link"
      >
        <icon
          :size="16"
          class="append-right-8"
          name="go-back"
        />
        <span class="ide-external-links-text">
          {{ s__('Go back') }}
        </span>
      </a>
    </p>
  </nav>
</template>
