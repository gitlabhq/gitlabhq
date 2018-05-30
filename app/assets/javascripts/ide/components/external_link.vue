<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showButtons() {
      return this.file.permalink;
    },
  },
};
</script>

<template>
  <div
    v-if="showButtons"
    class="pull-right ide-btn-group"
  >
    <a
      :href="file.permalink"
      target="_blank"
      :title="s__('IDE|Open in file view')"
      rel="noopener noreferrer"
    >
      <span class="vertical-align-middle">Open in file view</span>
      <icon
        name="external-link"
        css-classes="vertical-align-middle space-right"
        :size="16"
      />
    </a>
  </div>
</template>
