<script>
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import getCiCatalogSettingsQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_settings.query.graphql';
import catalogReleasesQuery from '../graphql/queries/catalog_releases.query.graphql';

/**
 * Renderless component that wraps GraphQL queries for CI/CD Catalog information
 * and updates the data for files which need this logic.
 *
 * You can use the slot to define a presentation for catalog release information.

 * Usage:
 *
 * ```vue
 * <ci-cd-catalog-wrapper
 *   #default="{ isCatalogRelease, detailsPagePath }"
 *   :release-path="release.tagPath"
 * >
 *   <gl-badge v-if="isCatalogRelease" :href="detailsPagePath">{{ __('CI/CD Catalog') }}</gl-badge>
 * </ci-cd-catalog-wrapper>
 * ```
 *
 */

export default {
  name: 'CiCdCatalogWrapper',
  i18n: {
    catalogResourceQueryError: s__(
      'CiCatalog|There was a problem fetching the CI/CD Catalog setting.',
    ),
    catalogReleasesQueryError: s__(
      'CiCatalog|There was a problem fetching the CI/CD Catalog releases.',
    ),
  },
  inject: ['projectPath'],
  props: {
    releasePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      catalogReleases: [],
      isCiCdCatalogProject: false,
    };
  },
  apollo: {
    isCiCdCatalogProject: {
      query: getCiCatalogSettingsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update({ project }) {
        return project?.isCatalogResource || false;
      },
      error() {
        createAlert({ message: this.$options.i18n.catalogResourceQueryError });
      },
    },
    catalogReleases: {
      query: catalogReleasesQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      skip() {
        return !this.isCiCdCatalogProject;
      },
      update({ ciCatalogResource }) {
        return ciCatalogResource?.versions?.nodes.map((version) => version.path) || [];
      },
      error() {
        createAlert({ message: this.$options.i18n.catalogReleasesQueryError });
      },
    },
  },
  computed: {
    detailsPagePath() {
      return this.isCatalogRelease ? `/explore/catalog/${this.projectPath}` : '';
    },
    isCatalogRelease() {
      return this.isCiCdCatalogProject ? this.catalogReleases?.includes(this.releasePath) : false;
    },
  },
  render() {
    return this.$scopedSlots.default({
      isCatalogRelease: this.isCatalogRelease,
      isCiCdCatalogProject: this.isCiCdCatalogProject,
      detailsPagePath: this.detailsPagePath,
    });
  },
};
</script>
