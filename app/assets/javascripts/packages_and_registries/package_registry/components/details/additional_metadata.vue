<script>
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import Composer from '~/packages_and_registries/package_registry/components/details/metadata/composer.vue';
import Conan from '~/packages_and_registries/package_registry/components/details/metadata/conan.vue';
import Maven from '~/packages_and_registries/package_registry/components/details/metadata/maven.vue';
import Nuget from '~/packages_and_registries/package_registry/components/details/metadata/nuget.vue';
import Pypi from '~/packages_and_registries/package_registry/components/details/metadata/pypi.vue';
import {
  FETCH_PACKAGE_METADATA_ERROR_MESSAGE,
  PACKAGE_TYPE_COMPOSER,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_PYPI,
} from '~/packages_and_registries/package_registry/constants';
import getPackageMetadataQuery from '../../graphql/queries/get_package_metadata.query.graphql';
import AdditionalMetadataLoader from './additional_metadata_loader.vue';

export default {
  components: {
    Composer,
    Conan,
    GlAlert,
    Maven,
    Nuget,
    Pypi,
    AdditionalMetadataLoader,
  },
  props: {
    packageId: {
      type: String,
      required: true,
    },
    packageType: {
      type: String,
      required: true,
    },
  },
  apollo: {
    packageMetadata: {
      query: getPackageMetadataQuery,
      variables() {
        return {
          id: this.packageId,
        };
      },
      update(data) {
        return data.package?.metadata || null;
      },
      error(error) {
        this.fetchPackageMetadataError = true;
        Sentry.captureException(error);
      },
    },
  },
  data() {
    return {
      packageMetadata: null,
      fetchPackageMetadataError: false,
    };
  },
  computed: {
    metadataComponent() {
      return {
        [PACKAGE_TYPE_COMPOSER]: Composer,
        [PACKAGE_TYPE_CONAN]: Conan,
        [PACKAGE_TYPE_MAVEN]: Maven,
        [PACKAGE_TYPE_NUGET]: Nuget,
        [PACKAGE_TYPE_PYPI]: Pypi,
      }[this.packageType];
    },
    showMetadata() {
      return this.metadataComponent && this.packageMetadata;
    },
    isLoading() {
      return this.$apollo.queries.packageMetadata.loading;
    },
  },
  i18n: {
    componentTitle: s__('PackageRegistry|Additional metadata'),
    fetchPackageMetadataErrorMessage: FETCH_PACKAGE_METADATA_ERROR_MESSAGE,
  },
};
</script>

<template>
  <div>
    <h3 v-if="isLoading || showMetadata" class="gl-text-lg" data-testid="title">
      {{ $options.i18n.componentTitle }}
    </h3>
    <gl-alert
      v-if="fetchPackageMetadataError"
      variant="danger"
      @dismiss="fetchPackageMetadataError = false"
    >
      {{ $options.i18n.fetchPackageMetadataErrorMessage }}
    </gl-alert>
    <additional-metadata-loader v-if="isLoading" />
    <div
      v-if="showMetadata"
      class="gl-rounded-base gl-bg-strong gl-shadow-inner-1-gray-100"
      data-testid="main"
    >
      <component
        :is="metadataComponent"
        :package-metadata="packageMetadata"
        data-testid="component-is"
      />
    </div>
  </div>
</template>
