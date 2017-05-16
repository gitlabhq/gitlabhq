<script>
  import tooltipMixin from '../../mixins/tooltip';

  export default {
    mixins: [
      tooltipMixin,
    ],
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
    computed: {
      iconClass() {
        return `fa-${this.icon}`;
      },
    },
  };
</script>

<template>
  <button
    type="button"
    class="toolbar-btn js-md hidden-xs"
    tabindex="-1"
    ref="tooltip"
    data-container="body"
    :data-md-tag="tag"
    :data-md-block="tagBlock"
    :data-md-prepend="prepend"
    :title="buttonTitle"
    :aria-label="buttonTitle">
    <i
      aria-hidden="true"
      class="fa fa-fw"
      :class="iconClass">
    </i>
  </button>
</template>
