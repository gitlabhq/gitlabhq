<script>
import {
  GlDropdown,
  GlDropdownForm,
  GlButton,
  GlFormInputGroup,
  GlDropdownDivider,
  GlDropdownItem,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import Link from '../extensions/link';
import { hasSelection } from '../services/utils';
import EditorStateObserver from './editor_state_observer.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownForm,
    GlFormInputGroup,
    GlDropdownDivider,
    GlDropdownItem,
    GlButton,
    EditorStateObserver,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor'],
  data() {
    return {
      linkHref: '',
      isActive: false,
    };
  },
  methods: {
    resetFields() {
      this.imgSrc = '';
      this.$refs.fileSelector.value = '';
    },
    openFileUpload() {
      this.$refs.fileSelector.click();
    },
    updateLinkState({ editor }) {
      const { canonicalSrc, href } = editor.getAttributes(Link.name);

      this.isActive = editor.isActive(Link.name);
      this.linkHref = canonicalSrc || href;
    },
    updateLink() {
      this.tiptapEditor
        .chain()
        .focus()
        .unsetLink()
        .setLink({
          href: this.linkHref,
          canonicalSrc: this.linkHref,
        })
        .run();

      this.$emit('execute', { contentType: Link.name });
    },
    selectLink() {
      const { tiptapEditor } = this;

      // a selection has already been made by the user, so do nothing
      if (!hasSelection(tiptapEditor)) {
        tiptapEditor.chain().focus().extendMarkRange(Link.name).run();
      }
    },
    removeLink() {
      this.tiptapEditor.chain().focus().unsetLink().run();

      this.$emit('execute', { contentType: Link.name });
    },
    onFileSelect(e) {
      this.tiptapEditor
        .chain()
        .focus()
        .uploadAttachment({
          file: e.target.files[0],
        })
        .run();

      this.resetFields();
      this.$emit('execute', { contentType: Link.name });
    },
  },
};
</script>
<template>
  <editor-state-observer @transaction="updateLinkState">
    <gl-dropdown
      v-gl-tooltip
      :aria-label="__('Insert link')"
      :title="__('Insert link')"
      :toggle-class="{ active: isActive }"
      size="small"
      category="tertiary"
      icon="link"
      @show="selectLink()"
    >
      <gl-dropdown-form class="gl-px-3!">
        <gl-form-input-group v-model="linkHref" :placeholder="__('Link URL')">
          <template #append>
            <gl-button variant="confirm" @click="updateLink">{{ __('Apply') }}</gl-button>
          </template>
        </gl-form-input-group>
      </gl-dropdown-form>
      <gl-dropdown-divider />
      <gl-dropdown-item v-if="isActive" @click="removeLink">
        {{ __('Remove link') }}
      </gl-dropdown-item>
      <gl-dropdown-item v-else @click="openFileUpload">
        {{ __('Upload file') }}
      </gl-dropdown-item>

      <input
        ref="fileSelector"
        type="file"
        name="content_editor_attachment"
        class="gl-display-none"
        @change="onFileSelect"
      />
    </gl-dropdown>
  </editor-state-observer>
</template>
