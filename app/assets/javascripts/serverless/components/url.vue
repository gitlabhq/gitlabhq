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
    <div class="gl-cursor-text label label-monospace monospace" data-testid="url-text-field">
      {{ uri }}
    </div>
    <clipboard-button
      :text="uri"
      :title="s__('ServerlessURL|Copy URL')"
      class="input-group-text js-clipboard-btn"
    />
  </div>
</template>
