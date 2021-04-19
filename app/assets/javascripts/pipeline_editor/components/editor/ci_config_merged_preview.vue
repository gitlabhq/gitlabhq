<script>
import { GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';
import EditorLite from '~/vue_shared/components/editor_lite.vue';

export default {
  i18n: {
    viewOnlyMessage: s__('Pipelines|Merged YAML is view only'),
  },
  components: {
    EditorLite,
    GlIcon,
  },
  inject: ['ciConfigPath'],
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      failureType: null,
    };
  },
  computed: {
    fileGlobalId() {
      return `${this.ciConfigPath}-${uniqueId()}`;
    },
    mergedYaml() {
      return this.ciConfigData.mergedYaml;
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-align-items-center">
      <gl-icon :size="16" name="lock" class="gl-text-gray-500 gl-mr-3" />
      {{ $options.i18n.viewOnlyMessage }}
    </div>
    <div class="gl-mt-3 gl-border-solid gl-border-gray-100 gl-border-1">
      <editor-lite
        ref="editor"
        :value="mergedYaml"
        :file-name="ciConfigPath"
        :file-global-id="fileGlobalId"
        :editor-options="{ readOnly: true }"
        v-on="$listeners"
      />
    </div>
  </div>
</template>
