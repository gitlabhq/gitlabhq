<script>
  /* eslint-disable vue/require-default-prop */
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

  export default {
    props: {
      loading: {
        type: Boolean,
        required: false,
        default: false,
      },
      disabled: {
        type: Boolean,
        required: false,
        default: false,
      },
      label: {
        type: String,
        required: false,
      },
      containerClass: {
        type: [String, Array, Object],
        required: false,
        default: 'btn btn-align-content',
      },
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
    :class="containerClass"
    :disabled="loading || disabled"
    type="button"
    @click="onClick"
  >
    <transition name="fade">
      <gl-loading-icon
        v-if="loading"
        :inline="true"
        :class="{
          'append-right-5': label
        }"
        class="js-loading-button-icon"
      />
    </transition>
    <transition name="fade">
      <slot>
        <span
          v-if="label"
          class="js-loading-button-label"
        >
          {{ label }}
        </span>
      </slot>
    </transition>
  </button>
</template>
