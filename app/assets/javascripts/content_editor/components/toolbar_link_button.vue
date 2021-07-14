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
import { Editor as TiptapEditor } from '@tiptap/vue-2';
import { hasSelection } from '../services/utils';

export const linkContentType = 'link';

export default {
  components: {
    GlDropdown,
    GlDropdownForm,
    GlFormInputGroup,
    GlDropdownDivider,
    GlDropdownItem,
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    tiptapEditor: {
      type: TiptapEditor,
      required: true,
    },
  },
  data() {
    return {
      linkHref: '',
    };
  },
  computed: {
    isActive() {
      return this.tiptapEditor.isActive(linkContentType);
    },
  },
  mounted() {
    this.tiptapEditor.on('selectionUpdate', ({ editor }) => {
      const { canonicalSrc, href } = editor.getAttributes(linkContentType);

      this.linkHref = canonicalSrc || href;
    });
  },
  methods: {
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

      this.$emit('execute', { contentType: linkContentType });
    },
    selectLink() {
      const { tiptapEditor } = this;

      // a selection has already been made by the user, so do nothing
      if (!hasSelection(tiptapEditor)) {
        tiptapEditor.chain().focus().extendMarkRange(linkContentType).run();
      }
    },
    removeLink() {
      this.tiptapEditor.chain().focus().unsetLink().run();

      this.$emit('execute', { contentType: linkContentType });
    },
  },
};
</script>
<template>
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
          <gl-button variant="confirm" @click="updateLink()">{{ __('Apply') }}</gl-button>
        </template>
      </gl-form-input-group>
    </gl-dropdown-form>
    <gl-dropdown-divider v-if="isActive" />
    <gl-dropdown-item v-if="isActive" @click="removeLink()">
      {{ __('Remove link') }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
