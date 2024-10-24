<script>
import { GlBadge, GlButton, GlTab, GlTabs, GlSprintf, GlIcon, GlLink } from '@gitlab/ui';
import VueRouter from 'vue-router';
import { n__, s__, sprintf } from '~/locale';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { MODEL_ENTITIES } from '~/ml/model_registry/constants';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import ActionsDropdown from '~/ml/model_registry/components/actions_dropdown.vue';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import getModelQuery from '~/ml/model_registry/graphql/queries/get_model.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import DeleteDisclosureDropdownItem from '../components/delete_disclosure_dropdown_item.vue';
import LoadOrErrorOrShow from '../components/load_or_error_or_show.vue';
import DeleteModel from '../components/functional/delete_model.vue';

const ROUTE_DETAILS = 'details';
const ROUTE_VERSIONS = 'versions';

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
  { path: '*', redirect: { name: ROUTE_DETAILS } },
];

export default {
  name: 'ShowMlModelApp',
  components: {
    ActionsDropdown,
    DeleteDisclosureDropdownItem,
    TitleArea,
    GlButton,
    GlTabs,
    GlTab,
    GlBadge,
    LoadOrErrorOrShow,
    DeleteModel,
    TimeAgoTooltip,
    GlSprintf,
    GlIcon,
    GlLink,
  },
  mixins: [timeagoMixin],
  router: new VueRouter({
    routes,
  }),
  provide() {
    return {
      mlflowTrackingUrl: this.mlflowTrackingUrl,
      projectPath: this.projectPath,
      canWriteModelRegistry: this.canWriteModelRegistry,
      maxAllowedFileSize: this.maxAllowedFileSize,
      latestVersion: this.latestVersion,
      markdownPreviewPath: this.markdownPreviewPath,
      editModelPath: this.editModelPath,
      createModelVersionPath: this.createModelVersionPath,
      modelGid: this.modelGid,
    };
  },
  props: {
    modelId: {
      type: Number,
      required: true,
    },
    modelName: {
      type: String,
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
    editModelPath: {
      type: String,
      required: true,
    },
    createModelVersionPath: {
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
    maxAllowedFileSize: {
      type: Number,
      required: true,
    },
    latestVersion: {
      type: String,
      required: false,
      default: null,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    model: {
      query: getModelQuery,
      variables() {
        return {
          id: this.modelGid,
        };
      },
      update(data) {
        return data?.mlModel;
      },
      error(error) {
        this.handleError(error);
      },
    },
  },
  data() {
    return {
      errorMessage: '',
      model: {},
      modelGid: convertToGraphQLId('Ml::Model', this.modelId),
    };
  },
  computed: {
    versionCount() {
      return this.model?.versionCount || 0;
    },
    tabIndex() {
      return routes.findIndex(({ name }) => name === this.$route.name);
    },
    versionsCountLabel() {
      return n__('MlModelRegistry|%d version', 'MlModelRegistry|%d versions', this.versionCount);
    },
    description() {
      return this.model?.description || '';
    },
    isLoading() {
      return this.$apollo.queries.model.loading;
    },
    createdMessage() {
      return s__('MlModelRegistry|Model created %{timeAgo} by %{author}');
    },
    authorId() {
      return getIdFromGraphQLId(`${this.model.author.id}`);
    },
    showCreatedDetail() {
      return this.model?.author && this.model?.createdAt;
    },
  },
  methods: {
    goTo(name) {
      if (name !== this.$route.name) {
        this.$router.push({ name });
      }
    },
    modelDeleted() {
      visitUrlWithAlerts(this.indexModelsPath, [deletionSuccessfulAlert]);
    },
    handleError(error) {
      this.errorMessage = sprintf(
        s__('MlModelRegistry|Failed to load model with error: %{message}'),
        {
          message: error.message,
        },
      );

      Sentry.captureException(error, {
        tags: {
          vue_component: 'show_ml_model',
        },
      });
    },
  },
  i18n: {
    createModelVersionLinkTitle: s__('MlModelRegistry|Create model version'),
    editModelButtonLabel: s__('MlModelRegistry|Edit model'),
  },
  modelVersionEntity: MODEL_ENTITIES.modelVersion,
  ROUTE_DETAILS,
  ROUTE_VERSIONS,
};
</script>

<template>
  <delete-model :model-id="modelGid" @model-deleted="modelDeleted">
    <template #default="{ deleteModel }">
      <div>
        <title-area :title="modelName">
          <template #metadata-versions-count>
            <div
              v-if="showCreatedDetail"
              class="detail-page-header-body gl-flex-wrap gl-gap-x-2"
              data-testid="metadata"
            >
              <gl-icon name="machine-learning" />
              <gl-sprintf :message="createdMessage">
                <template #timeAgo>
                  <time-ago-tooltip :time="model.createdAt" />
                </template>
                <template #author>
                  <gl-link
                    class="js-user-link gl-font-bold !gl-text-gray-500"
                    :href="model.author.webUrl"
                    :data-user-id="authorId"
                  >
                    <span class="sm:gl-inline">{{ model.author.name }}</span>
                  </gl-link>
                </template>
              </gl-sprintf>
            </div>
          </template>

          <template #right-actions>
            <gl-button
              v-if="canWriteModelRegistry"
              data-testid="edit-model-button"
              variant="confirm"
              :href="editModelPath"
              >{{ $options.i18n.editModelButtonLabel }}</gl-button
            >
            <gl-button
              v-if="canWriteModelRegistry"
              data-testid="model-version-create-button"
              variant="confirm"
              :href="createModelVersionPath"
              >{{ $options.i18n.createModelVersionLinkTitle }}</gl-button
            >

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

        <load-or-error-or-show :is-loading="isLoading" :error-message="errorMessage">
          <gl-tabs class="gl-mt-4" :value="tabIndex">
            <gl-tab
              v-if="latestVersion"
              :title="s__('MlModelRegistry|Model card')"
              @click="goTo($options.ROUTE_DETAILS)"
            />
            <gl-tab v-if="latestVersion" @click="goTo($options.ROUTE_VERSIONS)">
              <template #title>
                {{ s__('MlModelRegistry|Versions') }}
                <gl-badge class="gl-tab-counter-badge">{{ versionCount }}</gl-badge>
              </template>
            </gl-tab>

            <router-view :model-id="model.id" :model="model" />
          </gl-tabs>
        </load-or-error-or-show>
      </div>
    </template>
  </delete-model>
</template>
