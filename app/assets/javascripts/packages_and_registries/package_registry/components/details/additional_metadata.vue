<script>
import Composer from '~/packages_and_registries/package_registry/components/details/metadata/composer.vue';
import Conan from '~/packages_and_registries/package_registry/components/details/metadata/conan.vue';
import Maven from '~/packages_and_registries/package_registry/components/details/metadata/maven.vue';
import Nuget from '~/packages_and_registries/package_registry/components/details/metadata/nuget.vue';
import Pypi from '~/packages_and_registries/package_registry/components/details/metadata/pypi.vue';
import {
  PACKAGE_TYPE_COMPOSER,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_PYPI,
} from '~/packages_and_registries/package_registry/constants';

export default {
  components: {
    Composer,
    Conan,
    Maven,
    Nuget,
    Pypi,
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  computed: {
    metadataComponent() {
      return {
        [PACKAGE_TYPE_COMPOSER]: Composer,
        [PACKAGE_TYPE_CONAN]: Conan,
        [PACKAGE_TYPE_MAVEN]: Maven,
        [PACKAGE_TYPE_NUGET]: Nuget,
        [PACKAGE_TYPE_PYPI]: Pypi,
      }[this.packageEntity.packageType];
    },
    showMetadata() {
      return this.metadataComponent && this.packageEntity.metadata;
    },
  },
};
</script>

<template>
  <div v-if="showMetadata">
    <h3 class="gl-font-lg" data-testid="title">{{ __('Additional Metadata') }}</h3>
    <div class="gl-bg-gray-50 gl-inset-border-1-gray-100 gl-rounded-base" data-testid="main">
      <component
        :is="metadataComponent"
        :package-entity="packageEntity"
        data-testid="component-is"
      />
    </div>
  </div>
</template>
