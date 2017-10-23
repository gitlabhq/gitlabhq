<script>

/* This is a re-usable vue component for rendering a button
   that will probably be sending off ajax requests and need
   to show the loading status by setting the `loading` option.
   This can also be used for initial page load when you don't
   know the action of the button yet by setting
   `loading: true, label: undefined`.

  Sample configuration:

  <loading-button
    :loading="true"
    :label="Hello"
    @click="..."
  />

*/

import loadingIcon from './loading_icon.vue';

export default {
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: false,
    },
  },
  components: {
    loadingIcon,
  },
  methods: {
    onClick(e) {
      this.$emit('click', e);
    },
  },
};
</script>

<template>
  <button
    class="btn btn-align-content"
    @click="onClick"
    type="button"
    :disabled="loading"
  >
      <transition name="expand-fade-sm">
        <loading-icon
          v-if="loading"
          :inline="true"
          class="js-loading-button-icon"
        />
      </transition>
      <transition name="expand-fade-sm">
        <span
          v-if="loading && label"
          class="append-right-5 js-loading-button-spacer"
        >
        </span>
      </transition>
      <transition name="expand-fade-md">
        <span
          v-if="label"
          class="js-loading-button-label"
        >
          {{ label }}
        </span>
      </transition>
  </button>
</template>
