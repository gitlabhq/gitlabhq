<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import CiResourceComponents from './ci_resource_components.vue';
import CiResourceReadme from './ci_resource_readme.vue';

export default {
  components: {
    CiResourceReadme,
    CiResourceComponents,
    GlTab,
    GlTabs,
  },
  componentStyles: ['gl-mt-3'],
  props: {
    resourcePath: {
      type: String,
      required: true,
    },
    version: {
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
    <gl-tab :title="$options.i18n.tabs.components" lazy>
      <ci-resource-components :class="$options.componentStyles" :resource-path="resourcePath" />
    </gl-tab>
    <gl-tab :title="$options.i18n.tabs.readme" lazy>
      <ci-resource-readme
        :class="$options.componentStyles"
        :resource-path="resourcePath"
        :version="version"
      />
    </gl-tab>
  </gl-tabs>
</template>
