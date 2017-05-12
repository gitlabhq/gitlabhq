<script>
  export default {
    props: {
      buttonTitle: {
        type: String,
        required: true,
      },
      icon: {
        type: String,
        required: true,
      },
      tag: {
        type: String,
        required: true,
      },
      tagBlock: {
        type: String,
        required: false,
        default: '',
      },
      prepend: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
  };
</script>

<template>
  <button
    type="button"
    class="toolbar-btn js-md hidden-xs"
    tabindex="-1"
    :data-md-tag="tag"
    :data-md-block="tagBlock"
    :data-md-prepend="prepend"
    data-container="body"
    data-toggle="tooltip"
    :title="buttonTitle"
    :aria-label="buttonTitle">
    <i
      aria-hidden="true"
      class="fa fa-fw"
      :class="'fa-' + icon">
    </i>
  </button>
</template>
