<script>
import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';

export default {
  components: {
    ClipboardButton,
  },
  props: {
    uri: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="clipboard-group">
    <div class="url-text-field label label-monospace monospace">{{ uri }}</div>
    <clipboard-button
      :text="uri"
      :title="s__('ServerlessURL|Copy URL')"
      class="input-group-text js-clipboard-btn"
    />
  </div>
</template>
