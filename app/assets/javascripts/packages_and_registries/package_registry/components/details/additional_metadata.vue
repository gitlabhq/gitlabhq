<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { PackageType } from '~/packages/shared/constants';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

export default {
  i18n: {
    sourceText: s__('PackageRegistry|Source project located at %{link}'),
    licenseText: s__('PackageRegistry|License information located at %{link}'),
    recipeText: s__('PackageRegistry|Recipe: %{recipe}'),
    appGroup: s__('PackageRegistry|App group: %{group}'),
    appName: s__('PackageRegistry|App name: %{name}'),
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
  computed: {
    showMetadata() {
      const visibilityConditions = {
        [PackageType.NUGET]: this.packageEntity.nuget_metadatum,
        [PackageType.CONAN]: this.packageEntity.conan_metadatum,
        [PackageType.MAVEN]: this.packageEntity.maven_metadatum,
      };
      return visibilityConditions[this.packageEntity.package_type];
    },
  },
};
</script>

<template>
  <div v-if="showMetadata">
    <h3 class="gl-font-lg" data-testid="title">{{ __('Additional Metadata') }}</h3>

    <div class="gl-bg-gray-50 gl-inset-border-1-gray-100 gl-rounded-base" data-testid="main">
      <template v-if="packageEntity.nuget_metadatum">
        <details-row icon="project" padding="gl-p-4" dashed data-testid="nuget-source">
          <gl-sprintf :message="$options.i18n.sourceText">
            <template #link>
              <gl-link :href="packageEntity.nuget_metadatum.project_url" target="_blank">{{
                packageEntity.nuget_metadatum.project_url
              }}</gl-link>
            </template>
          </gl-sprintf>
        </details-row>
        <details-row icon="license" padding="gl-p-4" data-testid="nuget-license">
          <gl-sprintf :message="$options.i18n.licenseText">
            <template #link>
              <gl-link :href="packageEntity.nuget_metadatum.license_url" target="_blank">{{
                packageEntity.nuget_metadatum.license_url
              }}</gl-link>
            </template>
          </gl-sprintf>
        </details-row>
      </template>

      <details-row
        v-else-if="packageEntity.conan_metadatum"
        icon="information-o"
        padding="gl-p-4"
        data-testid="conan-recipe"
      >
        <gl-sprintf :message="$options.i18n.recipeText">
          <template #recipe>{{ packageEntity.name }}</template>
        </gl-sprintf>
      </details-row>

      <template v-else-if="packageEntity.maven_metadatum">
        <details-row icon="information-o" padding="gl-p-4" dashed data-testid="maven-app">
          <gl-sprintf :message="$options.i18n.appName">
            <template #name>
              <strong>{{ packageEntity.maven_metadatum.app_name }}</strong>
            </template>
          </gl-sprintf>
        </details-row>
        <details-row icon="information-o" padding="gl-p-4" data-testid="maven-group">
          <gl-sprintf :message="$options.i18n.appGroup">
            <template #group>
              <strong>{{ packageEntity.maven_metadatum.app_group }}</strong>
            </template>
          </gl-sprintf>
        </details-row>
      </template>
    </div>
  </div>
</template>
