<script>
import { COMMENT_FORM } from '../i18n';

export default {
  i18n: COMMENT_FORM.attachmentMsg,
  data() {
    return {
      message: this.$options.i18n,
    };
  },
};
</script>

<template>
  <div class="issuable-note-warning" data-testid="attachment-warning">
    {{ message }}
  </div>
</template>
