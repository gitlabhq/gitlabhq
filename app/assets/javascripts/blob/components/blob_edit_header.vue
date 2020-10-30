<script>
import { GlFormInput, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlFormInput,
    GlButton,
  },
  inheritAttrs: false,
  props: {
    value: {
      type: String,
      required: true,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: true,
    },
    showDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      name: this.value,
    };
  },
};
</script>
<template>
  <div class="js-file-title file-title-flex-parent">
    <div class="gl-display-flex gl-align-items-center gl-w-full">
      <gl-form-input
        v-model="name"
        :placeholder="
          s__('Snippets|Give your file a name to add code highlighting, e.g. example.rb for Ruby')
        "
        name="snippet_file_name"
        class="form-control js-snippet-file-name"
        type="text"
        v-bind="$attrs"
        @change="$emit('input', name)"
      />
      <gl-button
        v-if="showDelete"
        class="gl-ml-4"
        variant="danger"
        category="secondary"
        :disabled="!canDelete"
        data-qa-selector="delete_file_button"
        @click="$emit('delete')"
        >{{ s__('Snippets|Delete file') }}</gl-button
      >
    </div>
  </div>
</template>
