<script>
import { GlIcon } from '@gitlab/ui';

export default {
  name: 'NoteAttachment',
  components: {
    GlIcon,
  },
  props: {
    attachment: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="note-attachment">
    <a
      v-if="attachment.image"
      ref="attachmentImage"
      :href="attachment.url"
      target="_blank"
      rel="noopener noreferrer"
    >
      <img :src="attachment.url" class="note-image-attach col-lg-4" />
    </a>
    <div class="attachment">
      <a
        v-if="attachment.url"
        ref="attachmentUrl"
        :href="attachment.url"
        target="_blank"
        rel="noopener noreferrer"
      >
        <gl-icon name="paperclip" /> {{ attachment.filename }}
      </a>
    </div>
  </div>
</template>
