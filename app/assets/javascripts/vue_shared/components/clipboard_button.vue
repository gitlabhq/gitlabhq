<script>
  /**
   * Falls back to the code used in `copy_to_clipboard.js`
   */

  export default {
    name: 'ClipboardButton',
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
    :data-title="title"
    :data-clipboard-text="text"
  >
    <i
      aria-hidden="true"
      class="fa fa-clipboard"
    >
    </i>
  </button>
</template>
