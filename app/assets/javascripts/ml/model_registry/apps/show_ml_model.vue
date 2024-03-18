<script>
import { GlTab, GlTabs, GlBadge, GlAlert } from '@gitlab/ui';
import VueRouter from 'vue-router';
import { n__, s__, sprintf } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { MODEL_ENTITIES } from '~/ml/model_registry/constants';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import CandidateList from '~/ml/model_registry/components/candidate_list.vue';
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import ActionsDropdown from '~/ml/model_registry/components/actions_dropdown.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import DeleteDisclosureDropdownItem from '../components/delete_disclosure_dropdown_item.vue';
import destroyModelMutation from '../graphql/mutations/destroy_model.mutation.graphql';

const ROUTE_DETAILS = 'details';
const ROUTE_VERSIONS = 'versions';
const ROUTE_CANDIDATES = 'candidates';

const makeDeleteModelErrorMessage = (message) => {
  if (!message) return '';

  return sprintf(s__('MlModelRegistry|Failed to delete model with error: %{message}'), {
    message,
  });
};

const deletionSuccessfulAlert = {
  id: 'ml-model-deleted-successfully',
  message: s__('MlModelRegistry|Model deleted successfully'),
  variant: 'success',
};

const routes = [
  {
    path: '/',
    name: ROUTE_DETAILS,
    component: ModelDetail,
  },
  {
    path: '/versions',
    name: ROUTE_VERSIONS,
    component: ModelVersionList,
  },
  {
    path: '/candidates',
    name: ROUTE_CANDIDATES,
    component: CandidateList,
  },
  { path: '*', redirect: { name: ROUTE_DETAILS } },
];

export default {
  name: 'ShowMlModelApp',
  components: {
    ActionsDropdown,
    DeleteDisclosureDropdownItem,
    TitleArea,
    GlTabs,
    GlTab,
    GlBadge,
    MetadataItem,
    GlAlert,
  },
  router: new VueRouter({
    routes,
  }),
  provide() {
    return {
      mlflowTrackingUrl: this.mlflowTrackingUrl,
    };
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    indexModelsPath: {
      type: String,
      required: true,
    },
    canWriteModelRegistry: {
      type: Boolean,
      required: true,
    },
    mlflowTrackingUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      errorMessage: '',
    };
  },
  computed: {
    versionCount() {
      return this.model.versionCount || 0;
    },
    candidateCount() {
      return this.model.candidateCount || 0;
    },
    tabIndex() {
      return routes.findIndex(({ name }) => name === this.$route.name);
    },
    versionsCountLabel() {
      return n__(
        'MlModelRegistry|%d version',
        'MlModelRegistry|%d versions',
        this.model.versionCount,
      );
    },
  },
  methods: {
    goTo(name) {
      if (name !== this.$route.name) {
        this.$router.push({ name });
      }
    },
    async deleteModel() {
      this.errorMessage = '';
      try {
        const variables = {
          projectPath: this.projectPath,
          id: convertToGraphQLId('Ml::Model', this.model.id),
        };

        const { data } = await this.$apollo.mutate({
          mutation: destroyModelMutation,
          variables,
        });

        this.errorMessage = makeDeleteModelErrorMessage(data?.mlModelDestroy?.errors?.join(', '));

        if (!this.errorMessage) {
          visitUrlWithAlerts(this.indexModelsPath, [deletionSuccessfulAlert]);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = makeDeleteModelErrorMessage(error.message);
      }
    },
  },
  modelVersionEntity: MODEL_ENTITIES.modelVersion,
  ROUTE_DETAILS,
  ROUTE_VERSIONS,
  ROUTE_CANDIDATES,
};
</script>

<template>
  <div>
    <title-area :title="model.name">
      <template #metadata-versions-count>
        <metadata-item icon="machine-learning" :text="versionsCountLabel" />
      </template>

      <template #sub-header>
        {{ model.description }}
      </template>
      <template #right-actions>
        <actions-dropdown>
          <delete-disclosure-dropdown-item
            v-if="canWriteModelRegistry"
            :action-primary-text="s__('MlModelRegistry|Delete model')"
            :modal-title="s__('MlModelRegistry|Delete model?')"
            :delete-confirmation-text="
              s__(
                'MlExperimentTracking|Deleting this model will delete the associated model versions, candidates and artifacts.',
              )
            "
            @confirm-deletion="deleteModel"
          />
        </actions-dropdown>
      </template>
    </title-area>

    <gl-alert v-if="errorMessage" :dismissible="false" variant="danger" class="gl-mb-3">
      {{ errorMessage }}
    </gl-alert>

    <gl-tabs class="gl-mt-4" :value="tabIndex">
      <gl-tab :title="s__('MlModelRegistry|Details')" @click="goTo($options.ROUTE_DETAILS)" />
      <gl-tab @click="goTo($options.ROUTE_VERSIONS)">
        <template #title>
          {{ s__('MlModelRegistry|Versions') }}
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ versionCount }}</gl-badge>
        </template>
      </gl-tab>
      <gl-tab @click="goTo($options.ROUTE_CANDIDATES)">
        <template #title>
          {{ s__('MlModelRegistry|Version candidates') }}
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ candidateCount }}</gl-badge>
        </template>
      </gl-tab>

      <router-view :model-id="model.id" :model="model" />
    </gl-tabs>
  </div>
</template>
