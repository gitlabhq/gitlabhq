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
    packageEntity: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <details-row
      v-if="packageEntity.metadata.projectUrl"
      icon="project"
      padding="gl-p-4"
      dashed
      data-testid="nuget-source"
    >
      <gl-sprintf :message="$options.i18n.sourceText">
        <template #link>
          <gl-link :href="packageEntity.metadata.projectUrl" target="_blank">{{
            packageEntity.metadata.projectUrl
          }}</gl-link>
        </template>
      </gl-sprintf>
    </details-row>
    <details-row
      v-if="packageEntity.metadata.licenseUrl"
      icon="license"
      padding="gl-p-4"
      data-testid="nuget-license"
    >
      <gl-sprintf :message="$options.i18n.licenseText">
        <template #link>
          <gl-link :href="packageEntity.metadata.licenseUrl" target="_blank">{{
            packageEntity.metadata.licenseUrl
          }}</gl-link>
        </template>
      </gl-sprintf>
    </details-row>
  </div>
</template>
