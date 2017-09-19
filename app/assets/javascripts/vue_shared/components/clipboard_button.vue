<script>
  import Clipboard from 'vendor/clipboard';

  export default {
    name: 'clipboardButton',
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
    mounted() {
      // return new Clipboard(this.$refs.btn, {
      //   text: () => {
      //     return this.text;
      //   },
      // });
    }
  };
</script>

<template>
  <button
    type="button"
    class="btn btn-transparent btn-clipboard"
    :data-title="title"
    :data-clipboard-text="text"
    ref="btn"
    >
      <i
        aria-hidden="true"
        class="fa fa-clipboard">
      </i>
  </button>
</template>
