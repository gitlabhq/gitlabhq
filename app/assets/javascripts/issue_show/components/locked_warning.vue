<script>
import { __, sprintf } from '~/locale';

export default {
  computed: {
    currentPath() {
      return window.location.pathname;
    },
    alertMessage() {
      return sprintf(
        __(
          'Someone edited the issue at the same time you did. Please check out %{linkStart}the issue%{linkEnd} and make sure your changes will not unintentionally remove theirs.',
        ),
        {
          linkStart: `<a href="${this.currentPath}" target="_blank" rel="nofollow">`,
          linkEnd: `</a>`,
        },
        false,
      );
    },
  },
};
</script>

<template>
  <div class="alert alert-danger" v-html="alertMessage"></div>
</template>
