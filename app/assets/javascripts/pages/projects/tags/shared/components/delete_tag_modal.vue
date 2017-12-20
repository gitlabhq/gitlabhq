<script>
  import axios from '~/lib/utils/axios_utils';

  import Flash from '~/flash';
  import { s__, sprintf } from '~/locale';
  import modal from '~/vue_shared/components/modal.vue';
  import confirmationInput from '~/vue_shared/components/confirmation_input.vue';
  import { redirectTo } from '~/lib/utils/url_utility';

  import eventHub from '../event_hub';

  export default {
    components: {
      confirmationInput,
      modal,
    },
    props: {
      id: {
        type: String,
        required: false,
        default: 'delete-tag-modal',
      },
      tagName: {
        type: String,
        required: true,
      },
      url: {
        type: String,
        required: true,
      },
      redirectUrl: {
        type: String,
        required: true,
      },
    },
    computed: {
      text() {
        return sprintf(s__(`TagsPage|You're about to permanently delete the tag '%{tagName}'.
Once deleted, it cannot be undone or recovered.`), { tagName: this.tagName });
      },
      title() {
        return sprintf(s__("TagsPage|Delete tag '%{tagName}'?"), { tagName: this.tagName });
      },
    },
    methods: {
      canSubmit() {
        return this.$refs.confirmation && this.$refs.confirmation.hasCorrectValue();
      },
      onSubmit() {
        eventHub.$emit('deleteTagModal.requestStarted', this.ur);
        return axios.delete(this.url)
          .then(() => {
            eventHub.$emit('deleteTagModal.requestFinished', { url: this.url, successful: true });
            redirectTo(this.redirectUrl);
          })
          .catch((error) => {
            eventHub.$emit('deleteTagModal.requestFinished', { url: this.url, successful: false });
            if (error.response.status === 404) {
              Flash(sprintf(s__("TagsPage|Tag '%{tagName}' was not found"), { tagName: this.tagName }));
            } else {
              const errorMessage = error.response.data.message;
              Flash(sprintf(s__("TagsPage|Deleting tag '%{tagName}' failed (%{errorMessage})"), { tagName: this.tagName, errorMessage }));
            }
            throw error;
          });
      },
    },
  };
</script>

<template>
  <modal
    :id="id"
    :title="title"
    :text="text"
    kind="danger"
    :primary-button-label="s__('TagsPage|Delete tag')"
    @submit="onSubmit"
    :submit-disabled="!canSubmit()">

    <template
      slot="body"
      slot-scope="props">
      <p v-html="props.text"></p>

      <confirmationInput
        ref="confirmation"
        :input-id="`${id}-input`"
        confirmation-key="tag-name"
        :confirmation-value="tagName"
      />
    </template>

  </modal>
</template>
