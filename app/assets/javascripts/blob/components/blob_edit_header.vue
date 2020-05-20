<script>
import { GlFormInput } from '@gitlab/ui';

export default {
  components: {
    GlFormInput,
  },
  inheritAttrs: false,
  props: {
    value: {
      type: String,
      required: true,
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
    <gl-form-input
      id="snippet_file_name"
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
  </div>
</template>
