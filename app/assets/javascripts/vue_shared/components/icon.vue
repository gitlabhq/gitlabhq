<script>

/* This is a re-usable vue component for rendering a svg sprite
   icon

  Sample configuration:

  <icon
    :img-src="userAvatarSrc"
    :img-alt="tooltipText"
    :tooltip-text="tooltipText"
    tooltip-placement="top"
  />

*/

  export default {
    props: {
      name: {
        type: String,
        required: true,
      },

      size: {
        type: Number,
        required: false,
        default: 0,
      },

      cssClass: {
        type: String,
        required: false,
        default: '',
      },
    },

    computed: {
      spriteHref() {
        return `${gon.sprite_icons}#${this.name}`
      },
      fullCssClass() {
        let classString = '' || this.cssClass;
        if (this.size) classString += `s${this.size}`
        return classString;
      },
    },
  };
</script>
<template>
  <svg
    :class="fullCssClass">
    <use v-bind="{'xlink:href':spriteHref}"/>
  </svg>
</template>
