<script>
import { EDITOR_READY_EVENT } from '~/editor/constants';
import { CiSchemaExtension } from '~/editor/extensions/source_editor_ci_schema_ext';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SOURCE_EDITOR_DEBOUNCE } from '../../constants';

export default {
  editorOptions: {
    // Quick suggestions is so that monaco can provide
    // autocomplete for keywords
    quickSuggestions: true,
  },
  debounceValue: SOURCE_EDITOR_DEBOUNCE,
  components: {
    SourceEditor,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['ciConfigPath'],
  inheritAttrs: false,
  methods: {
    onCiConfigUpdate(content) {
      this.$emit('updateCiConfig', content);
    },
    registerCiSchema({ detail: { instance } }) {
      if (this.glFeatures.schemaLinting) {
        instance.use({ definition: CiSchemaExtension });
        instance.registerCiSchema();
      }
    },
  },
  readyEvent: EDITOR_READY_EVENT,
};
</script>
<template>
  <div class="gl-border-solid gl-border-gray-100 gl-border-1 gl-border-t-none!">
    <source-editor
      ref="editor"
      :debounce-value="$options.debounceValue"
      :editor-options="$options.editorOptions"
      :file-name="ciConfigPath"
      v-bind="$attrs"
      @[$options.readyEvent]="registerCiSchema($event)"
      @input="onCiConfigUpdate"
      v-on="$listeners"
    />
  </div>
</template>
