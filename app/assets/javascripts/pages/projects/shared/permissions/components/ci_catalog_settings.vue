<script>
import { GlBadge, GlLink, GlLoadingIcon, GlModal, GlSprintf, GlToggle } from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/alert';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import getCiCatalogSettingsQuery from '../graphql/queries/get_ci_catalog_settings.query.graphql';
import catalogResourcesCreate from '../graphql/mutations/catalog_resources_create.mutation.graphql';

export const i18n = {
  badgeText: __('Experiment'),
  catalogResourceQueryError: s__(
    'CiCatalog|There was a problem fetching the CI/CD Catalog setting.',
  ),
  catalogResourceMutationError: s__(
    'CiCatalog|There was a problem marking the project as a CI/CD Catalog resource.',
  ),
  catalogResourceMutationSuccess: s__('CiCatalog|This project is now a CI/CD Catalog resource.'),
  ciCatalogLabel: s__('CiCatalog|CI/CD Catalog resource'),
  ciCatalogHelpText: s__(
    'CiCatalog|Mark project as a CI/CD Catalog resource. %{linkStart}What is the CI/CD Catalog?%{linkEnd}',
  ),
  modal: {
    actionPrimary: {
      text: s__('CiCatalog|Mark project as a CI/CD Catalog resource'),
    },
    actionCancel: {
      text: __('Cancel'),
    },
    body: s__(
      'CiCatalog|This project will be marked as a CI/CD Catalog resource and will be visible in the CI/CD Catalog. This action is not reversible.',
    ),
    title: s__('CiCatalog|Mark project as a CI/CD Catalog resource'),
  },
  readMeHelpText: s__(
    'CiCatalog|The project must contain a README.md file and a template.yml file. When enabled, the repository is available in the CI/CD Catalog.',
  ),
};

export const ciCatalogHelpPath = helpPagePath('ci/components/index', {
  anchor: 'components-catalog',
});

export default {
  i18n,
  components: {
    GlBadge,
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
      ciCatalogHelpPath,
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
    isLoading() {
      return this.$apollo.queries.isCatalogResource.loading;
    },
  },
  methods: {
    async markProjectAsCatalogResource() {
      try {
        const {
          data: {
            catalogResourcesCreate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: catalogResourcesCreate,
          variables: { input: { projectPath: this.fullPath } },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }

        this.isCatalogResource = true;
        createAlert({
          message: this.$options.i18n.catalogResourceMutationSuccess,
          variant: VARIANT_INFO,
        });
      } catch (error) {
        const message = error.message || this.$options.i18n.catalogResourceMutationError;
        createAlert({ message });
      }
    },
    onCatalogResourceEnabledToggled() {
      this.showCatalogResourceModal = true;
    },
    onModalCanceled() {
      this.showCatalogResourceModal = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" />
    <div v-else data-testid="ci-catalog-settings">
      <div>
        <label class="gl-mb-1 gl-mr-2">
          {{ $options.i18n.ciCatalogLabel }}
        </label>
        <gl-badge size="sm" variant="info"> {{ $options.i18n.badgeText }} </gl-badge>
      </div>
      <gl-sprintf :message="$options.i18n.ciCatalogHelpText">
        <template #link="{ content }">
          <gl-link :href="ciCatalogHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <gl-toggle
        class="gl-my-2"
        :disabled="isCatalogResource"
        :value="isCatalogResource"
        :label="$options.i18n.ciCatalogLabel"
        label-position="hidden"
        name="ci_resource_enabled"
        @change="onCatalogResourceEnabledToggled"
      />
      <div class="gl-text-secondary">
        {{ $options.i18n.readMeHelpText }}
      </div>
      <gl-modal
        :visible="showCatalogResourceModal"
        modal-id="mark-as-catalog-resource"
        size="sm"
        :title="$options.i18n.modal.title"
        :action-cancel="$options.i18n.modal.actionCancel"
        :action-primary="$options.i18n.modal.actionPrimary"
        @canceled="onModalCanceled"
        @primary="markProjectAsCatalogResource"
      >
        {{ $options.i18n.modal.body }}
      </gl-modal>
    </div>
  </div>
</template>
