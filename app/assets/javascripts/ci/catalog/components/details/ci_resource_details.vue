<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import ExperimentBadge from '~/vue_shared/components/badges/experiment_badge.vue';
import CiResourceComponents from './ci_resource_components.vue';
import CiResourceReadme from './ci_resource_readme.vue';

export default {
  components: {
    CiResourceReadme,
    CiResourceComponents,
    ExperimentBadge,
    GlTab,
    GlTabs,
  },
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
  // We can remove this class when we remove the experiment badge
  tabClass: 'gl-pb-4',
};
</script>

<template>
  <gl-tabs>
    <gl-tab :title-link-class="$options.tabClass" lazy>
      <!-- This template is simply to add the line height class.
      We can remove this when we remove the experiment badge and use the title prop. -->
      <template #title>
        <div class="gl-line-height-20">
          {{ $options.i18n.tabs.readme }}
        </div>
      </template>
      <ci-resource-readme :resource-path="resourcePath" :version="version" />
    </gl-tab>
    <gl-tab :title-link-class="$options.tabClass" lazy>
      <template #title>
        <div class="gl--flex-center gl-line-height-20">
          {{ $options.i18n.tabs.components }}
          <experiment-badge size="sm" class="gl-ml-2" />
        </div>
      </template>
      <ci-resource-components :resource-path="resourcePath" />
    </gl-tab>
  </gl-tabs>
</template>
<style></style>
