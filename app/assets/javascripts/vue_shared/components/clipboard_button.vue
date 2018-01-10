<script>
  import tooltip from '../directives/tooltip';
  /**
   * Falls back to the code used in `copy_to_clipboard.js`
   */

  export default {
    name: 'ClipboardButton',
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
    },
  };
</script>

<template>
  <button
    type="button"
    class="btn btn-transparent btn-clipboard"
    :title="title"
    :data-clipboard-text="text"
    v-tooltip
  >
    <i
      aria-hidden="true"
      class="fa fa-clipboard"
    >
    </i>
  </button>
</template>
