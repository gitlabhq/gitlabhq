<script>
import {
  GlLink,
  GlSprintf,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLoadingIcon,
  GlButton,
  GlButtonGroup,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { __ } from '~/locale';
import Audio from '../../extensions/audio';
import DrawioDiagram from '../../extensions/drawio_diagram';
import Image from '../../extensions/image';
import Video from '../../extensions/video';
import EditorStateObserver from '../editor_state_observer.vue';
import { acceptedMimes } from '../../services/upload_helpers';
import BubbleMenu from './bubble_menu.vue';

const MEDIA_TYPES = [Audio.name, Image.name, Video.name, DrawioDiagram.name];

export default {
  i18n: {
    copySourceLabels: {
      [Audio.name]: __('Copy audio URL'),
      [DrawioDiagram.name]: __('Copy diagram URL'),
      [Image.name]: __('Copy image URL'),
      [Video.name]: __('Copy video URL'),
    },
    editLabels: {
      [Audio.name]: __('Edit audio description'),
      [DrawioDiagram.name]: __('Edit diagram description'),
      [Image.name]: __('Edit image description'),
      [Video.name]: __('Edit video description'),
    },
    deleteLabels: {
      [Audio.name]: __('Delete audio'),
      [DrawioDiagram.name]: __('Delete diagram'),
      [Image.name]: __('Delete image'),
      [Video.name]: __('Delete video'),
    },
  },
  components: {
    BubbleMenu,
    GlSprintf,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
    GlButton,
    GlButtonGroup,
    EditorStateObserver,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  data() {
    return {
      mediaType: undefined,
      mediaSrc: undefined,
      mediaCanonicalSrc: undefined,
      mediaAlt: undefined,

      isEditing: false,
      isUpdating: false,

      uploading: false,

      uploadProgress: 0,
    };
  },
  computed: {
    copySourceLabel() {
      return this.$options.i18n.copySourceLabels[this.mediaType];
    },
    editLabel() {
      return this.$options.i18n.editLabels[this.mediaType];
    },
    deleteLabel() {
      return this.$options.i18n.deleteLabels[this.mediaType];
    },
    showProgressIndicator() {
      return this.uploading || this.isUpdating;
    },
    isDrawioDiagram() {
      return this.mediaType === DrawioDiagram.name;
    },
  },
  methods: {
    shouldShow() {
      const shouldShow = MEDIA_TYPES.some((type) => this.tiptapEditor.isActive(type));

      if (!shouldShow) this.isEditing = false;

      return shouldShow;
    },

    startEditingMedia() {
      this.isEditing = true;
    },

    endEditingMedia() {
      this.isEditing = false;

      this.updateMediaInfoToState();
    },

    cancelEditingMedia() {
      this.endEditingMedia();
      this.updateMediaInfoToState();
    },

    async saveEditedMedia() {
      this.isUpdating = true;

      this.mediaSrc = await this.contentEditor.resolveUrl(this.mediaCanonicalSrc);

      const position = this.tiptapEditor.state.selection.from;

      const attrs = {
        src: this.mediaSrc,
        alt: this.mediaAlt,
        canonicalSrc: this.mediaCanonicalSrc,
      };

      this.tiptapEditor.chain().focus().updateAttributes(this.mediaType, attrs).run();

      this.tiptapEditor.commands.setNodeSelection(position);

      this.endEditingMedia();

      this.isUpdating = false;
    },

    async updateMediaInfoToState() {
      this.mediaType = MEDIA_TYPES.find((type) => this.tiptapEditor.isActive(type));

      if (!this.mediaType) return;

      this.isUpdating = true;

      const { src, alt, canonicalSrc, uploading } = this.tiptapEditor.getAttributes(this.mediaType);

      this.mediaAlt = alt;
      this.mediaCanonicalSrc = canonicalSrc || src;

      this.uploading = uploading;

      this.mediaSrc = await this.contentEditor.resolveUrl(this.mediaCanonicalSrc);

      this.isUpdating = false;
    },

    onTransaction({ transaction }) {
      const { uploading = '', progress = 0 } = transaction.getMeta('uploadProgress') || {};
      if (this.uploading === uploading) {
        this.uploadProgress = Math.round(progress * 100);
      }
    },

    resetMediaInfo() {
      this.mediaAlt = null;
      this.mediaCanonicalSrc = null;
      this.uploading = false;

      this.uploadProgress = 0;
    },

    editDiagram() {
      this.tiptapEditor.chain().focus().createOrEditDiagram().run();
    },

    onFileSelect(e) {
      this.tiptapEditor
        .chain()
        .focus()
        .deleteSelection()
        .uploadAttachment({
          file: e.target.files[0],
        })
        .run();

      this.$refs.fileSelector.value = '';
    },

    copyMediaSrc() {
      navigator.clipboard.writeText(this.mediaCanonicalSrc);
    },

    deleteMedia() {
      this.tiptapEditor.chain().focus().deleteSelection().run();
    },
  },

  acceptedMimes,
};
</script>
<template>
  <editor-state-observer
    :debounce="0"
    @selectionUpdate="updateMediaInfoToState"
    @transaction="onTransaction"
  >
    <bubble-menu
      data-testid="media-bubble-menu"
      class="gl-rounded-base gl-bg-white gl-shadow"
      plugin-key="bubbleMenuMedia"
      :should-show="shouldShow"
      @show="updateMediaInfoToState"
      @hidden="resetMediaInfo"
    >
      <gl-button-group v-if="!isEditing" class="gl-flex gl-items-center">
        <gl-loading-icon v-if="showProgressIndicator" class="gl-pl-4 gl-pr-3" />
        <span v-if="uploading" class="gl-pr-3 gl-text-subtle">
          <gl-sprintf :message="__('Uploading: %{progress}')">
            <template #progress>{{ uploadProgress }}&percnt;</template>
          </gl-sprintf>
        </span>
        <input
          ref="fileSelector"
          type="file"
          name="content_editor_image"
          :accept="$options.acceptedMimes[mediaType]"
          class="gl-hidden"
          @change="onFileSelect"
        />
        <gl-link
          v-if="!showProgressIndicator"
          v-gl-tooltip
          :href="mediaSrc"
          :aria-label="mediaCanonicalSrc"
          :title="mediaCanonicalSrc"
          target="_blank"
          class="gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap gl-px-3"
        >
          {{ mediaCanonicalSrc }}
        </gl-link>
        <gl-button
          v-if="!showProgressIndicator"
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="edit-media"
          :aria-label="editLabel"
          :title="editLabel"
          icon="pencil"
          @click="startEditingMedia"
        />
        <gl-button
          v-if="isDrawioDiagram"
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="edit-diagram"
          :aria-label="editLabel"
          :title="editLabel"
          icon="diagram"
          @click="editDiagram"
        />
      </gl-button-group>
      <gl-form v-else class="bubble-menu-form gl-w-full gl-p-4" @submit.prevent="saveEditedMedia">
        <gl-form-group :label="__('URL')" label-for="media-src">
          <gl-form-input id="media-src" v-model="mediaCanonicalSrc" data-testid="media-src" />
        </gl-form-group>
        <gl-form-group :label="__('Alt text')" label-for="media-alt">
          <gl-form-input id="media-alt" v-model="mediaAlt" data-testid="media-alt" />
        </gl-form-group>
        <div class="gl-flex gl-justify-end">
          <gl-button
            class="gl-mr-3"
            data-testid="cancel-editing-media"
            @click="cancelEditingMedia"
            >{{ __('Cancel') }}</gl-button
          >
          <gl-button variant="confirm" type="submit">{{ __('Apply') }}</gl-button>
        </div>
      </gl-form>
    </bubble-menu>
  </editor-state-observer>
</template>
