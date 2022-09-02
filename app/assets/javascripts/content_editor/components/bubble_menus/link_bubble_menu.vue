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
      linkTitle: undefined,

      isEditing: false,
    };
  },
  methods: {
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

      if (!this.linkCanonicalSrc && !this.linkHref) {
        this.removeLink();
      }
    },

    cancelEditingLink() {
      this.endEditingLink();
      this.updateLinkToState();
    },

    async saveEditedLink() {
      if (!this.linkCanonicalSrc) {
        this.removeLink();
      } else {
        this.tiptapEditor
          .chain()
          .focus()
          .extendMarkRange(Link.name)
          .updateAttributes(Link.name, {
            href: this.linkCanonicalSrc,
            canonicalSrc: this.linkCanonicalSrc,
            title: this.linkTitle,
          })
          .run();
      }

      this.endEditingLink();
    },

    updateLinkToState() {
      const editor = this.tiptapEditor;

      const { href, title, canonicalSrc } = editor.getAttributes(Link.name);

      if (
        canonicalSrc === this.linkCanonicalSrc &&
        href === this.linkHref &&
        title === this.linkTitle
      ) {
        return;
      }

      this.linkTitle = title;
      this.linkHref = href;
      this.linkCanonicalSrc = canonicalSrc || href;

      this.isEditing = !this.linkCanonicalSrc;
    },

    copyLinkHref() {
      navigator.clipboard.writeText(this.linkCanonicalSrc);
    },

    removeLink() {
      this.tiptapEditor.chain().focus().extendMarkRange(Link.name).unsetLink().run();
    },

    resetBubbleMenuState() {
      this.linkTitle = undefined;
      this.linkHref = undefined;
      this.linkCanonicalSrc = undefined;
    },
  },
  tippyOptions: {
    placement: 'bottom',
  },
};
</script>
<template>
  <bubble-menu
    data-testid="link-bubble-menu"
    class="gl-shadow gl-rounded-base gl-bg-white"
    plugin-key="bubbleMenuLink"
    :should-show="shouldShow"
    :tippy-options="$options.tippyOptions"
    @show="updateLinkToState"
    @hidden="resetBubbleMenuState"
  >
    <editor-state-observer @selectionUpdate="updateLinkToState">
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
        <gl-form-group :label="__('URL')" label-for="link-href">
          <gl-form-input id="link-href" v-model="linkCanonicalSrc" data-testid="link-href" />
        </gl-form-group>
        <gl-form-group :label="__('Title')" label-for="link-title">
          <gl-form-input id="link-title" v-model="linkTitle" data-testid="link-title" />
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
    </editor-state-observer>
  </bubble-menu>
</template>
