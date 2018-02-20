<script>
  import axios from '~/lib/utils/axios_utils';
  import Modal from '~/vue_shared/components/modal.vue';

  export default {
    name: 'NoteAttachment',
    components: {
      Modal,
    },
    props: {
      attachment: {
        type: Object,
        required: true,
      },
      deleteAttachmentPath: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        showModal: false,
        loading: false,
      };
    },
    methods: {
      removeAttachment() {
        this.loading = true;

        axios({
          url: this.deleteAttachmentPath,
          method: 'delete',
        })
          .then((res) => {
            this.showModal = false;
            this.loading = false;
            this.$emit('disableEditing');
          })
          .catch((err) => {
            this.loading = false;
            throw err;
          });

      }
    }
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
          aria-hidden="true">
        </i>
        {{ attachment.filename }}
      </a>
      <button
        type="button"
        class="btn btn-transparent"
        title="Delete this attachment"
        @click.prevent="showModal = true"
      >
        <i class="fa fa-trash-o cred" />
      </button>
      <modal
        v-if="showModal"
        kind="danger"
        text="Are you sure you want to remove the attachment?"
        primary-button-label="Remove attachment"
        :submitDisabled="loading"
        @submit="removeAttachment"
        @cancel="showModal = false"
      />
    </div>
  </div>
</template>
