<script>
import { GlButton } from '@gitlab/ui';
import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
    GlButton,
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
      :title="s__('ServerlessURL|Copy URL to clipboard')"
      class="input-group-text js-clipboard-btn"
    />
    <gl-button
      :href="uri"
      target="_blank"
      rel="noopener noreferrer nofollow"
      class="input-group-text btn btn-default"
    >
      <icon name="external-link" />
    </gl-button>
  </div>
</template>
