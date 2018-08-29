<script>

// only allow classes in images.scss e.g. s12
const validSizes = [8, 10, 12, 16, 18, 24, 32, 48, 72];
let iconValidator = () => true;

/*
 During development/tests we want to validate that we are just using icons that are actually defined
*/
if (process.env.NODE_ENV !== 'production') {
  // eslint-disable-next-line global-require
  const data = require('@gitlab-org/gitlab-svgs/dist/icons.json');
  const { icons } = data;
  iconValidator = value => {
    if (icons.includes(value)) {
      return true;
    }
    // eslint-disable-next-line no-console
    console.warn(`Icon '${value}' is not a known icon of @gitlab/gitlab-svg`);
    return false;
  };
}

/** This is a re-usable vue component for rendering a svg sprite icon
 *  @example
 *  <icon
 *    name="retry"
 *    :size="32"
 *    css-classes="top"
 *  />
 */
export default {
  props: {
    name: {
      type: String,
      required: true,
      validator: iconValidator,
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

    tabIndex: {
      type: String,
      required: false,
      default: null,
    },
  },

  computed: {
    spriteHref() {
      return `${gon.sprite_icons}#${this.name}`;
    },
    iconTestClass() {
      return `ic-${this.name}`;
    },
    iconSizeClass() {
      return this.size ? `s${this.size}` : '';
    },
  },
};
</script>

<template>
  <svg
    :class="[iconSizeClass, iconTestClass, cssClasses]"
    :width="width"
    :height="height"
    :x="x"
    :y="y"
    :tabindex="tabIndex"
  >
    <use v-bind="{ 'xlink:href':spriteHref }"/>
  </svg>
</template>
