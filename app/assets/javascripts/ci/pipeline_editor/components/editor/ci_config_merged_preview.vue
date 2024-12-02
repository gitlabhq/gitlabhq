<script>
import { GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';
import SourceEditor from '~/vue_shared/components/source_editor.vue';

export default {
  i18n: {
    viewOnlyMessage: s__('Pipelines|Full configuration is view only'),
  },
  components: {
    SourceEditor,
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
    <div class="gl-flex gl-items-center">
      <gl-icon class="gl-mr-3" :size="16" name="lock" variant="subtle" />
      {{ $options.i18n.viewOnlyMessage }}
    </div>
    <div class="gl-mt-3 gl-border-1 gl-border-solid gl-border-default">
      <source-editor
        ref="editor"
        :value="mergedYaml"
        :file-name="ciConfigPath"
        :file-global-id="fileGlobalId"
        :editor-options="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          readOnly: true,
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        v-on="$listeners"
      />
    </div>
  </div>
</template>
