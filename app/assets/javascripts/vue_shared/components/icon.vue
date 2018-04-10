<script>

  /* This is a re-usable vue component for rendering a svg sprite
    icon

    Sample configuration:

    <icon
      name="retry"
      :size="32"
      css-classes="top"
    />

  */
  // only allow classes in images.scss e.g. s12
  const validSizes = [8, 12, 16, 18, 24, 32, 48, 72];

  export default {
    props: {
      name: {
        type: String,
        required: true,
      },

      size: {
        type: Number,
        required: false,
        default: 16,
        validator(value) {
          return validSizes.includes(value);
        },
      },

      cssClasses: {
        type: String,
        required: false,
        default: '',
      },

      width: {
        type: Number,
        required: false,
        default: null,
      },

      height: {
        type: Number,
        required: false,
        default: null,
      },

      y: {
        type: Number,
        required: false,
        default: null,
      },

      x: {
        type: Number,
        required: false,
        default: null,
      },
    },

    computed: {
      spriteHref() {
        return `${gon.sprite_icons}#${this.name}`;
      },
      iconSizeClass() {
        return this.size ? `s${this.size}` : '';
      },
    },
  };
</script>

<template>
  <svg
    :class="[iconSizeClass, cssClasses]"
    :width="width"
    :height="height"
    :x="x"
    :y="y">
    <use v-bind="{ 'xlink:href':spriteHref }" />
  </svg>
</template>
