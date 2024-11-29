<script>
import {
  GlLink,
  GlSprintf,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlButton,
  GlButtonGroup,
  GlLoadingIcon,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { getMarkType, getMarkRange } from '@tiptap/core';
import Link from '../../extensions/link';
import EditorStateObserver from '../editor_state_observer.vue';
import BubbleMenu from './bubble_menu.vue';

export default {
  components: {
    BubbleMenu,
    GlSprintf,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlButton,
    GlButtonGroup,
    GlLoadingIcon,
    EditorStateObserver,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  data() {
    return {
      linkHref: undefined,
      linkCanonicalSrc: undefined,
      linkText: undefined,

      isEditing: false,

      uploading: false,
      uploadProgress: 0,
    };
  },
  methods: {
    linkIsEmpty() {
      return (
        !this.linkCanonicalSrc &&
        !this.linkHref &&
        (!this.linkText || this.linkText === this.linkTextInDoc())
      );
    },

    linkTextInDoc() {
      const { state } = this.tiptapEditor;
      const type = getMarkType(Link.name, state.schema);
      let { selection: range } = state;
      if (range.from === range.to) {
        range =
          getMarkRange(state.selection.$from, type) ||
          getMarkRange(state.selection.$to, type) ||
          {};
      }

      if (!range.from || !range.to) return '';

      return state.doc.textBetween(range.from, range.to, ' ');
    },

    shouldShow() {
      return this.tiptapEditor.isActive(Link.name);
    },

    startEditingLink() {
      // select the entire link
      this.tiptapEditor.chain().focus().extendMarkRange(Link.name).run();

      this.isEditing = true;
    },

    async endEditingLink() {
      this.isEditing = false;

      this.linkHref = await this.contentEditor.resolveUrl(this.linkCanonicalSrc);
    },

    cancelEditingLink() {
      this.endEditingLink();

      if (this.linkIsEmpty()) {
        this.removeLink();
      } else {
        this.updateLinkToState();
      }
    },

    async saveEditedLink() {
      const chain = this.tiptapEditor.chain().focus();

      const attrs = {
        href: this.linkCanonicalSrc,
        canonicalSrc: this.linkCanonicalSrc,
      };

      // if nothing was entered by the user and the link is empty, remove it
      // since we don't want to insert an empty link
      if (this.linkIsEmpty()) {
        this.removeLink();
        return;
      }

      if (!this.linkText) {
        this.linkText = this.linkCanonicalSrc;
      }

      // if link text was updated, insert a new link in the doc with the new text
      if (this.linkTextInDoc() !== this.linkText) {
        chain
          .extendMarkRange(Link.name)
          .setMeta('preventAutolink', true)
          .insertContent({
            marks: [{ type: Link.name, attrs }],
            type: 'text',
            text: this.linkText,
          })
          .run();
      } else {
        // if link text was not updated, just update the attributes
        chain.updateAttributes(Link.name, attrs).run();
      }

      this.endEditingLink();
    },

    updateLinkToState() {
      const editor = this.tiptapEditor;
      const { href, canonicalSrc, uploading } = editor.getAttributes(Link.name);
      const text = this.linkTextInDoc();

      this.uploading = uploading;

      if (
        canonicalSrc === this.linkCanonicalSrc &&
        href === this.linkHref &&
        text === this.linkText
      ) {
        return;
      }

      this.linkText = text;
      this.linkHref = href;
      this.linkCanonicalSrc = canonicalSrc || href;
    },

    onTransaction({ transaction }) {
      this.linkText = this.linkTextInDoc();
      if (transaction.getMeta('creatingLink')) {
        this.isEditing = true;
      }

      const { filename = '', progress = 0 } = transaction.getMeta('uploadProgress') || {};
      if (this.uploading === filename) {
        this.uploadProgress = Math.round(progress * 100);
      }
    },

    copyLinkHref() {
      navigator.clipboard.writeText(this.linkCanonicalSrc);
    },

    removeLink() {
      const chain = this.tiptapEditor.chain().focus();
      if (this.linkTextInDoc()) {
        chain.unsetLink().run();
      } else {
        chain
          .insertContent({
            type: 'text',
            text: ' ',
          })
          .extendMarkRange(Link.name)
          .unsetLink()
          .deleteSelection()
          .run();
      }
    },

    resetBubbleMenuState() {
      this.linkText = undefined;
      this.linkHref = undefined;
      this.linkCanonicalSrc = undefined;

      this.isEditing = false;
    },
  },
  tippyOptions: {
    placement: 'bottom',
  },
};
</script>
<template>
  <editor-state-observer
    :debounce="0"
    @transaction="onTransaction"
    @selectionUpdate="updateLinkToState"
  >
    <bubble-menu
      data-testid="link-bubble-menu"
      class="gl-rounded-base gl-bg-white gl-shadow"
      plugin-key="bubbleMenuLink"
      :should-show="shouldShow"
      :tippy-options="$options.tippyOptions"
      @show="updateLinkToState"
      @hidden="resetBubbleMenuState"
    >
      <gl-button-group v-if="!isEditing" class="gl-flex gl-items-center">
        <gl-loading-icon v-if="uploading" class="gl-pl-4 gl-pr-3" />
        <span v-if="uploading" class="gl-pr-3 gl-text-subtle">
          <gl-sprintf :message="__('Uploading: %{progress}')">
            <template #progress>{{ uploadProgress }}&percnt;</template>
          </gl-sprintf>
        </span>
        <gl-link
          v-else
          v-gl-tooltip
          :href="linkHref"
          :aria-label="linkCanonicalSrc"
          :title="linkCanonicalSrc"
          target="_blank"
          class="gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap gl-px-3"
        >
          {{ linkCanonicalSrc }}
        </gl-link>
        <gl-button
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="copy-link-url"
          :aria-label="__('Copy link URL')"
          :title="__('Copy link URL')"
          icon="copy-to-clipboard"
          @click="copyLinkHref"
        />
        <gl-button
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="edit-link"
          :aria-label="__('Edit link')"
          :title="__('Edit link')"
          icon="pencil"
          @click="startEditingLink"
        />
        <gl-button
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="remove-link"
          :aria-label="__('Remove link')"
          :title="__('Remove link')"
          icon="unlink"
          @click="removeLink"
        />
      </gl-button-group>
      <gl-form v-else class="bubble-menu-form gl-w-full gl-p-4" @submit.prevent="saveEditedLink">
        <gl-form-group :label="__('Text')" label-for="link-text">
          <gl-form-input id="link-text" v-model="linkText" data-testid="link-text" />
        </gl-form-group>
        <gl-form-group :label="__('URL')" label-for="link-href">
          <gl-form-input
            id="link-href"
            v-model="linkCanonicalSrc"
            autofocus
            data-testid="link-href"
          />
        </gl-form-group>
        <div class="gl-flex gl-justify-end">
          <gl-button class="gl-mr-3" data-testid="cancel-link" @click="cancelEditingLink">
            {{ __('Cancel') }}
          </gl-button>
          <gl-button variant="confirm" type="submit">
            {{ __('Apply') }}
          </gl-button>
        </div>
      </gl-form>
    </bubble-menu>
  </editor-state-observer>
</template>
