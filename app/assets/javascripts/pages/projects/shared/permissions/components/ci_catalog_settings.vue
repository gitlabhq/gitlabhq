<script>
import { GlLink, GlLoadingIcon, GlSprintf, GlToggle, GlIcon, GlToastMixin } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { editProjectPath } from '~/lib/utils/path_helpers/project';

import getCiCatalogSettingsQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_settings.query.graphql';
import catalogResourcesCreate from '~/ci/catalog/graphql/mutations/catalog_resources_create.mutation.graphql';
import catalogResourcesDestroy from '~/ci/catalog/graphql/mutations/catalog_resources_destroy.mutation.graphql';
import CiCatalogSettingsRemovalModal from './ci_catalog_settings_removal_modal.vue';

const i18n = {
  catalogResourceQueryError: s__(
    'CiCatalog|There was a problem fetching the CI/CD Catalog setting.',
  ),
  setCatalogResourceMutationError: s__(
    'CiCatalog|Unable to set project as a CI/CD Catalog project.',
  ),
  removeCatalogResourceMutationError: s__(
    'CiCatalog|Unable to remove project as a CI/CD Catalog project.',
  ),
  setCatalogResourceMutationSuccess: s__('CiCatalog|This project is now a CI/CD Catalog project.'),
  removeCatalogResourceMutationSuccess: s__(
    'CiCatalog|This project is no longer a CI/CD Catalog project.',
  ),
  ciCatalogLabel: s__('CiCatalog|CI/CD Catalog project'),
  ciCatalogHelpText: s__(
    'CiCatalog|Set component project as a CI/CD Catalog project. %{linkStart}What is the CI/CD Catalog?%{linkEnd}',
  ),
  readMeHelpText: s__(
    'CiCatalog|The project will be findable in the CI/CD Catalog after the project has at least one release.',
  ),
  noDescriptionText: s__(
    'CiCatalog|To set the project as a catalog resource, provide a brief description in the %{linkStart}project settings%{linkEnd}.',
  ),
};

const ciCatalogHelpPath = helpPagePath('ci/components/_index', {
  anchor: 'cicd-catalog',
});

export default {
  name: 'CiCatalogSettings',
  components: {
    CiCatalogSettingsRemovalModal,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlToggle,
    GlIcon,
  },
  mixins: [GlToastMixin],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      ciCatalogProject: null,
      isCatalogResource: false,
      showCatalogResourceModal: false,
    };
  },
  apollo: {
    ciCatalogProject: {
      query: getCiCatalogSettingsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ project }) {
        return project;
      },
      error() {
        createAlert({ message: this.$options.i18n.catalogResourceQueryError });
      },
      result({ data }) {
        this.isCatalogResource = data?.project?.isCatalogResource || false;
      },
    },
  },
  computed: {
    successMessage() {
      return this.isCatalogResource
        ? this.$options.i18n.setCatalogResourceMutationSuccess
        : this.$options.i18n.removeCatalogResourceMutationSuccess;
    },
    errorMessage() {
      return this.isCatalogResource
        ? this.$options.i18n.removeCatalogResourceMutationError
        : this.$options.i18n.setCatalogResourceMutationError;
    },
    isLoading() {
      return this.$apollo.queries.ciCatalogProject.loading;
    },
    noDescriptionSet() {
      return !this.ciCatalogProject?.description?.length;
    },
    settingsLink() {
      return `${editProjectPath(this.fullPath)}#js-general-settings`;
    },
  },
  methods: {
    async toggleCatalogResourceMutation({ isCreating }) {
      this.showCatalogResourceModal = false;

      const mutation = isCreating ? catalogResourcesCreate : catalogResourcesDestroy;
      const mutationInput = isCreating ? 'catalogResourcesCreate' : 'catalogResourcesDestroy';

      try {
        const {
          data: {
            [mutationInput]: { errors },
          },
        } = await this.$apollo.mutate({
          mutation,
          variables: { input: { projectPath: this.fullPath } },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }

        this.isCatalogResource = !this.isCatalogResource;
        this.$toast.show(this.successMessage);
      } catch (error) {
        const message = error.message || this.errorMessage;
        createAlert({ message });
      }
    },
    onToggleCatalogResource() {
      if (this.isCatalogResource) {
        this.showCatalogResourceModal = true;
      } else {
        this.toggleCatalogResourceMutation({ isCreating: true });
      }
    },
    unlistCatalogResource() {
      this.toggleCatalogResourceMutation({ isCreating: false });
    },
  },
  i18n,
  ciCatalogHelpPath,
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" />
    <div v-else data-testid="ci-catalog-settings">
      <div class="gl-flex">
        <label class="gl-mb-1 gl-mr-3">
          {{ $options.i18n.ciCatalogLabel }}
        </label>
      </div>
      <gl-sprintf :message="$options.i18n.ciCatalogHelpText">
        <template #link="{ content }">
          <gl-link :href="$options.ciCatalogHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <div class="gl-my-2 gl-flex gl-items-center gl-gap-3">
        <gl-toggle
          :value="isCatalogResource"
          :label="$options.i18n.ciCatalogLabel"
          :disabled="noDescriptionSet"
          label-position="hidden"
          name="ci_resource_enabled"
          data-testid="catalog-resource-toggle"
          @change="onToggleCatalogResource"
        />
        <span v-if="noDescriptionSet" class="gl-text-subtle">
          <gl-icon name="warning" class="gl-text-warning" />
          <gl-sprintf :message="$options.i18n.noDescriptionText">
            <template #link="{ content }">
              <gl-link :href="settingsLink" data-testid="settings-link">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </span>
      </div>
      <div class="gl-text-subtle">
        {{ $options.i18n.readMeHelpText }}
      </div>
      <ci-catalog-settings-removal-modal
        v-if="showCatalogResourceModal"
        :full-path="fullPath"
        @close="showCatalogResourceModal = false"
        @primary="unlistCatalogResource"
      />
    </div>
  </div>
</template>
