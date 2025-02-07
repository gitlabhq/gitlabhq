<script>
import { GlLink, GlLoadingIcon, GlModal, GlSprintf, GlToggle } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import getCiCatalogSettingsQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_settings.query.graphql';
import catalogResourcesCreate from '~/ci/catalog/graphql/mutations/catalog_resources_create.mutation.graphql';
import catalogResourcesDestroy from '~/ci/catalog/graphql/mutations/catalog_resources_destroy.mutation.graphql';

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
  modal: {
    actionPrimary: {
      text: s__('CiCatalog|Remove from the CI/CD catalog'),
    },
    actionCancel: {
      text: __('Cancel'),
    },
    body: s__(
      "CiCatalog|The project and any released versions will be removed from the CI/CD Catalog. If you re-enable this toggle, the project's existing releases are not re-added to the catalog. You must %{linkStart}create a new release%{linkEnd}.",
    ),
    title: s__('CiCatalog|Remove component project from the CI/CD Catalog?'),
  },
  readMeHelpText: s__(
    'CiCatalog|The project will be findable in the CI/CD Catalog after the project has at least one release.',
  ),
};

const ciCatalogHelpPath = helpPagePath('ci/components/_index', {
  anchor: 'cicd-catalog',
});

const releasesHelpPath = helpPagePath('user/project/releases/release_cicd_examples');

export default {
  components: {
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    GlToggle,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isCatalogResource: false,
      showCatalogResourceModal: false,
    };
  },
  apollo: {
    isCatalogResource: {
      query: getCiCatalogSettingsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
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
      return this.$apollo.queries.isCatalogResource.loading;
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
    onModalCanceled() {
      this.showCatalogResourceModal = false;
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
  releasesHelpPath,
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
      <gl-toggle
        class="gl-my-2"
        :value="isCatalogResource"
        :label="$options.i18n.ciCatalogLabel"
        label-position="hidden"
        name="ci_resource_enabled"
        data-testid="catalog-resource-toggle"
        @change="onToggleCatalogResource"
      />
      <div class="gl-text-subtle">
        {{ $options.i18n.readMeHelpText }}
      </div>
      <gl-modal
        :visible="showCatalogResourceModal"
        modal-id="unlist-catalog-resource"
        size="sm"
        :title="$options.i18n.modal.title"
        :action-cancel="$options.i18n.modal.actionCancel"
        :action-primary="$options.i18n.modal.actionPrimary"
        @canceled="onModalCanceled"
        @primary="unlistCatalogResource"
      >
        <gl-sprintf :message="$options.i18n.modal.body">
          <template #link="{ content }">
            <gl-link :href="$options.releasesHelpPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-modal>
    </div>
  </div>
</template>
