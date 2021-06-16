<script>
import { GlModal, GlFormGroup, GlFormInput, GlTabs, GlTab } from '@gitlab/ui';
import { isSafeURL, joinPaths } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { IMAGE_TABS } from '../../constants';
import UploadImageTab from './upload_image_tab.vue';

export default {
  components: {
    UploadImageTab,
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlTabs,
    GlTab,
  },
  props: {
    imageRoot: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      file: null,
      urlError: null,
      imageUrl: null,
      description: null,
      tabIndex: IMAGE_TABS.UPLOAD_TAB,
      uploadImageTab: null,
    };
  },
  modalTitle: __('Image details'),
  okTitle: __('Insert image'),
  urlTabTitle: __('Link to an image'),
  urlLabel: __('Image URL'),
  descriptionLabel: __('Description'),
  uploadTabTitle: __('Upload an image'),
  computed: {
    altText() {
      return this.description;
    },
  },
  methods: {
    show() {
      this.file = null;
      this.urlError = null;
      this.imageUrl = null;
      this.description = null;
      this.tabIndex = IMAGE_TABS.UPLOAD_TAB;

      this.$refs.modal.show();
    },
    onOk(event) {
      if (this.tabIndex === IMAGE_TABS.UPLOAD_TAB) {
        this.submitFile(event);
        return;
      }
      this.submitURL(event);
    },
    setFile(file) {
      this.file = file;
    },
    submitFile(event) {
      const { file, altText } = this;
      const { uploadImageTab } = this.$refs;

      uploadImageTab.validateFile();

      if (uploadImageTab.fileError) {
        event.preventDefault();
        return;
      }

      const imageUrl = joinPaths(this.imageRoot, file.name);

      this.$emit('addImage', { imageUrl, file, altText: altText || file.name });
    },
    submitURL(event) {
      if (!this.validateUrl()) {
        event.preventDefault();
        return;
      }

      const { imageUrl, altText } = this;

      this.$emit('addImage', { imageUrl, altText: altText || imageUrl });
    },
    validateUrl() {
      if (!isSafeURL(this.imageUrl)) {
        this.urlError = __('Please provide a valid URL');
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
    :title="$options.modalTitle"
    :ok-title="$options.okTitle"
    @ok="onOk"
  >
    <gl-tabs v-model="tabIndex">
      <!-- Upload file Tab -->
      <gl-tab :title="$options.uploadTabTitle">
        <upload-image-tab ref="uploadImageTab" @input="setFile" />
      </gl-tab>

      <!-- By URL Tab -->
      <gl-tab :title="$options.urlTabTitle">
        <gl-form-group
          class="gl-mt-5 gl-mb-3"
          :label="$options.urlLabel"
          label-for="url-input"
          :state="!Boolean(urlError)"
          :invalid-feedback="urlError"
        >
          <gl-form-input id="url-input" ref="urlInput" v-model="imageUrl" />
        </gl-form-group>
      </gl-tab>
    </gl-tabs>

    <!-- Description Input -->
    <gl-form-group :label="$options.descriptionLabel" label-for="description-input">
      <gl-form-input id="description-input" ref="descriptionInput" v-model="description" />
    </gl-form-group>
  </gl-modal>
</template>
