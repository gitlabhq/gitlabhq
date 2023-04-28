<script>
import {
  GlLink,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlButton,
  GlButtonGroup,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { getMarkType, getMarkRange } from '@tiptap/core';
import Link from '../../extensions/link';
import EditorStateObserver from '../editor_state_observer.vue';
import BubbleMenu from './bubble_menu.vue';

export default {
  components: {
    BubbleMenu,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
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
      linkHref: undefined,
      linkCanonicalSrc: undefined,
      linkText: undefined,

      isEditing: false,
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
      const { href, canonicalSrc } = editor.getAttributes(Link.name);
      const text = this.linkTextInDoc();

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
    appendTo: () => document.body,
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
      class="gl-shadow gl-rounded-base gl-bg-white"
      plugin-key="bubbleMenuLink"
      :should-show="shouldShow"
      :tippy-options="$options.tippyOptions"
      @show="updateLinkToState"
      @hidden="resetBubbleMenuState"
    >
      <gl-button-group v-if="!isEditing" class="gl-display-flex gl-align-items-center">
        <gl-link
          v-gl-tooltip
          :href="linkHref"
          :aria-label="linkCanonicalSrc"
          :title="linkCanonicalSrc"
          target="_blank"
          class="gl-px-3 gl-overflow-hidden gl-white-space-nowrap gl-text-overflow-ellipsis"
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
      <gl-form v-else class="bubble-menu-form gl-p-4 gl-w-100" @submit.prevent="saveEditedLink">
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
        <div class="gl-display-flex gl-justify-content-end">
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
