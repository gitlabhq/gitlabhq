<script>
  import tooltip from '../../directives/tooltip';
  import icon from '../icon.vue';

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
    components: {
      icon,
    },
    directives: {
      tooltip,
    },
  };
</script>

<template>
  <button
    v-tooltip
    type="button"
    class="toolbar-btn js-md"
    tabindex="-1"
    data-container="body"
    :data-md-tag="tag"
    :data-md-block="tagBlock"
    :data-md-prepend="prepend"
    :title="buttonTitle"
    :aria-label="buttonTitle">
    <icon
      :name="icon">
    </icon>
  </button>
</template>
