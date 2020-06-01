<script>
import { isSafeURL } from '~/lib/utils/url_utility';
import { GlModal, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
  },
  data() {
    return {
      error: null,
      imageUrl: null,
      altText: null,
      modalTitle: __('Image Details'),
      okTitle: __('Insert'),
      urlLabel: __('Image URL'),
      descriptionLabel: __('Description'),
    };
  },
  methods: {
    show() {
      this.error = null;
      this.imageUrl = null;
      this.altText = null;

      this.$refs.modal.show();
    },
    onOk(event) {
      if (!this.isValid()) {
        event.preventDefault();
        return;
      }

      const { imageUrl, altText } = this;

      this.$emit('addImage', { imageUrl, altText: altText || __('image') });
    },
    isValid() {
      if (!isSafeURL(this.imageUrl)) {
        this.error = __('Please provide a valid URL');
        this.$refs.urlInput.$el.focus();
        return false;
      }

      return true;
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    modal-id="add-image-modal"
    :title="modalTitle"
    :ok-title="okTitle"
    @ok="onOk"
  >
    <gl-form-group
      :label="urlLabel"
      label-for="url-input"
      :state="!Boolean(error)"
      :invalid-feedback="error"
    >
      <gl-form-input id="url-input" ref="urlInput" v-model="imageUrl" />
    </gl-form-group>

    <gl-form-group :label="descriptionLabel" label-for="description-input">
      <gl-form-input id="description-input" ref="descriptionInput" v-model="altText" />
    </gl-form-group>
  </gl-modal>
</template>
