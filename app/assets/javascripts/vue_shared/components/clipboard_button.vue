<script>
  import tooltip from '../directives/tooltip';
  /**
   * Falls back to the code used in `copy_to_clipboard.js`
   */
  import tooltip from '../directives/tooltip';

  export default {
<<<<<<< HEAD
    name: 'clipboardButton',
=======
    name: 'ClipboardButton',
>>>>>>> 74da79113bb2eb7363403d7c2a9f1e0624590b74
    directives: {
      tooltip,
    },
    props: {
      text: {
        type: String,
        required: true,
      },
      title: {
        type: String,
        required: true,
      },
      tooltipPlacement: {
        type: String,
        required: false,
        default: 'top',
      },
      tooltipContainer: {
        type: [String, Boolean],
        required: false,
        default: false,
      },
    },
  };
</script>

<template>
  <button
    type="button"
    class="btn btn-transparent btn-clipboard"
<<<<<<< HEAD
    v-tooltip
    data-container="body"
    :title="title"
    :data-clipboard-text="text"
  >
    <i
      aria-hidden="true"
      class="fa fa-clipboard">
=======
    :title="title"
    :data-clipboard-text="text"
    v-tooltip
    :data-container="tooltipContainer"
    :data-placement="tooltipPlacement"
  >
    <i
      aria-hidden="true"
      class="fa fa-clipboard"
    >
>>>>>>> 74da79113bb2eb7363403d7c2a9f1e0624590b74
    </i>
  </button>
</template>
