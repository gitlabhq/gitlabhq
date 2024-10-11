<script>
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import getCiCatalogSettingsQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_settings.query.graphql';

/**
 * Renderless component that wraps GraphQL queries for CI/CD Catalog information
 * and updates the data for files which need this logic.
 *
 * You can use the slot to define a presentation for catalog release information.

 * Usage:
 *
 * ```vue
 * <ci-cd-catalog-wrapper
 *   #default="{ isCiCdCatalogProject }"
 * >
 *   <gl-button :disabled="isCiCdCatalogProject">{{ __('New release') }}</gl-button>
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
  },
  inject: ['projectPath'],
  data() {
    return {
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
  },
  render() {
    return this.$scopedSlots.default({
      isCiCdCatalogProject: this.isCiCdCatalogProject,
    });
  },
};
</script>
