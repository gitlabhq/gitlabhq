<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

export default {
  i18n: {
    sourceText: s__('PackageRegistry|Source project located at %{link}'),
    licenseText: s__('PackageRegistry|License information located at %{link}'),
  },
  components: {
    DetailsRow,
    GlLink,
    GlSprintf,
  },
  props: {
    packageMetadata: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <details-row
      v-if="packageMetadata.projectUrl"
      icon="project"
      padding="gl-p-4"
      dashed
      data-testid="nuget-source"
    >
      <gl-sprintf :message="$options.i18n.sourceText">
        <template #link>
          <gl-link :href="packageMetadata.projectUrl" target="_blank">{{
            packageMetadata.projectUrl
          }}</gl-link>
        </template>
      </gl-sprintf>
    </details-row>
    <details-row
      v-if="packageMetadata.licenseUrl"
      icon="license"
      padding="gl-p-4"
      data-testid="nuget-license"
    >
      <gl-sprintf :message="$options.i18n.licenseText">
        <template #link>
          <gl-link :href="packageMetadata.licenseUrl" target="_blank">{{
            packageMetadata.licenseUrl
          }}</gl-link>
        </template>
      </gl-sprintf>
    </details-row>
  </div>
</template>
