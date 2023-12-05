<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CiResourceComponents from './ci_resource_components.vue';
import CiResourceReadme from './ci_resource_readme.vue';

export default {
  components: {
    CiResourceReadme,
    CiResourceComponents,
    GlTab,
    GlTabs,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    resourcePath: {
      type: String,
      required: true,
    },
  },
  i18n: {
    tabs: {
      components: s__('CiCatalog|Components'),
      readme: s__('CiCatalog|Readme'),
    },
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab :title="$options.i18n.tabs.readme" lazy>
      <ci-resource-readme :resource-path="resourcePath" />
    </gl-tab>
    <gl-tab v-if="glFeatures.ciCatalogComponentsTab" :title="$options.i18n.tabs.components" lazy>
      <ci-resource-components :resource-path="resourcePath"
    /></gl-tab>
  </gl-tabs>
</template>
<style></style>
