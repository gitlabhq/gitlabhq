<script>
export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },

  computed: {
    iconClass() {
      return `fa fa-${this.icon}`;
    },
    buttonClass() {
      return `btn has-tooltip`;
    },
  },
  updated() {
    $(this.$el).tooltip('destroy');
  },
};
</script>

<template>
  <button
    type="button"
    :class="buttonClass"
    :title="title"
    :aria-label="title"
    data-container="body"
    data-placement="top"
    :disabled="isLoading">
    <i
      :class="iconClass"
      aria-hidden="true" />
    <i
      class="fa fa-spinner fa-spin"
      aria-hidden="true"
      v-if="isLoading" />
  </button>
</template>
