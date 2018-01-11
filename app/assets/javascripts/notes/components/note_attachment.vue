<script>
  export default {
    name: 'NoteAttachment',
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
      :href="attachment.url"
      target="_blank"
      rel="noopener noreferrer">
      <img
        :src="attachment.url"
        class="note-image-attach"
      />
    </a>
    <div class="attachment">
      <a
        v-if="attachment.url"
        :href="attachment.url"
        target="_blank"
        rel="noopener noreferrer">
        <i
          class="fa fa-paperclip"
<<<<<<< HEAD
          aria-hidden="true"
        >
=======
          aria-hidden="true">
>>>>>>> upstream/master
        </i>
        {{ attachment.filename }}
      </a>
    </div>
  </div>
</template>
