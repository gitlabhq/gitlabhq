<script>
  import tooltip from '../../directives/tooltip';
  import icon from '../icon.vue';

  export default {
    components: {
      icon,
    },
    directives: {
      tooltip,
    },
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
      tagSelect: {
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
    methods: {
      clicked() {
        this.$emit('click', this);
      },
    },
  };
</script>

<template>
  <button
    v-tooltip
    :title="buttonTitle"
    :aria-label="buttonTitle"
    type="button"
    class="toolbar-btn"
    tabindex="-1"
    data-container="body"
    @click.stop.prevent="clicked"
  >
    <icon
      :name="icon"
    />
  </button>
</template>
