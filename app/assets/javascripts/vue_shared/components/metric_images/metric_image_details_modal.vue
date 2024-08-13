<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput, GlModal } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { __, s__, sprintf } from '~/locale';
import { isValidURL } from '~/lib/utils/url_utility';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlModal,
  },
  props: {
    edit: {
      type: Boolean,
      required: false,
      default: false,
    },
    imageFiles: {
      type: [Array, FileList],
      required: false,
      default: () => [],
    },
    imageId: {
      type: Number,
      required: false,
      default: null,
    },
    filename: {
      type: String,
      required: false,
      default: '',
    },
    visible: {
      type: Boolean,
      required: true,
    },
    url: {
      type: String,
      required: false,
      default: '',
    },
    urlText: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      modalUrl: this.url,
      modalUrlText: this.urlText,
    };
  },
  computed: {
    ...mapState(['isUploadingImage']),
    title() {
      return this.edit
        ? sprintf(this.$options.i18n.editTitle, { filename: this.filename })
        : this.$options.i18n.uploadTitle;
    },
    isUrlValid() {
      return this.modalUrl === '' || isValidURL(this.modalUrl);
    },
  },
  methods: {
    ...mapActions(['uploadImage', 'updateImage']),
    clear() {
      this.modalUrl = this.url;
      this.modalUrlText = this.urlText;
      this.$emit('hidden');
    },
    async submit() {
      if (!this.isUrlValid) {
        this.$refs.urlInput.$el.focus();
        return;
      }

      if (this.edit) {
        await this.updateImage({
          imageId: this.imageId,
          url: this.modalUrl,
          urlText: this.modalUrlText,
        });
        this.clear();

        return;
      }

      await this.uploadImage({
        files: this.imageFiles,
        url: this.modalUrl,
        urlText: this.modalUrlText,
      });
      this.clear();
    },
  },
  i18n: {
    cancel: __('Cancel'),
    description: s__(
      "Incidents|Add text or a link to display with your image. If you don't add either, the file name displays instead.",
    ),
    invalidUrlMessage: __('Invalid URL'),
    textInputLabel: __('Text (optional)'),
    urlInputLabel: __('Link (optional)'),
    urlInputDescription: s__('Incidents|Must start with http:// or https://'),
    editTitle: s__('Incident|Editing %{filename}'),
    uploadTitle: s__('Incidents|Add image details'),
    update: __('Update'),
    upload: __('Upload'),
  },
};
</script>

<template>
  <gl-modal
    modal-id="metric-image-details-modal"
    size="sm"
    :title="title"
    :visible="visible"
    @hidden="clear"
  >
    <p v-if="!edit" data-testid="metric-image-details-modal-description">
      {{ $options.i18n.description }}
    </p>

    <gl-form
      id="metric-image-details-modal-form"
      data-testid="metric-image-details-modal-form"
      @submit.prevent="submit"
    >
      <gl-form-group
        :label="$options.i18n.textInputLabel"
        label-for="metric-image-details-modal-text-input"
      >
        <gl-form-input
          id="metric-image-details-modal-text-input"
          v-model="modalUrlText"
          data-testid="metric-image-details-modal-text-input"
        />
      </gl-form-group>

      <gl-form-group
        data-testid="metric-image-details-url-form-group"
        :label="$options.i18n.urlInputLabel"
        label-for="metric-image-details-modal-url-input"
        :description="$options.i18n.urlInputDescription"
        :invalid-feedback="$options.i18n.invalidUrlMessage"
        :state="isUrlValid"
      >
        <gl-form-input
          id="metric-image-details-modal-url-input"
          ref="urlInput"
          v-model="modalUrl"
          data-testid="metric-image-details-modal-url-input"
          :state="isUrlValid"
          lazy
        />
      </gl-form-group>
    </gl-form>

    <template #modal-footer>
      <gl-button category="primary" variant="default" @click="clear">
        {{ $options.i18n.cancel }}
      </gl-button>

      <gl-button
        form="metric-image-details-modal-form"
        :loading="isUploadingImage"
        category="primary"
        variant="confirm"
        type="submit"
      >
        {{ edit ? $options.i18n.update : $options.i18n.upload }}
      </gl-button>
    </template>
  </gl-modal>
</template>
