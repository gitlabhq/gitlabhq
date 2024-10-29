<script>
import { GlAvatar, GlBadge, GlButton, GlTab, GlTabs, GlSprintf, GlIcon, GlLink } from '@gitlab/ui';
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
import DeleteModelDisclosureDropdownItem from '../components/delete_model_disclosure_dropdown_item.vue';
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
    DeleteModelDisclosureDropdownItem,
    TitleArea,
    GlAvatar,
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
    showModelAuthor() {
      return this.model?.author;
    },
    showModelLatestVersion() {
      return Boolean(this.model?.latestVersion);
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
    tabModelCardTitle: s__('MlModelRegistry|Model card'),
    tabVersionsTitle: s__('MlModelRegistry|Versions'),
    versionCountTitle: s__('MlModelRegistry|Total versions'),
    latestVersionTitle: s__('MlModelRegistry|Latest version'),
    authorTitle: s__('MlModelRegistry|Publisher'),
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
              <delete-model-disclosure-dropdown-item
                v-if="canWriteModelRegistry"
                @confirm-deletion="deleteModel"
              />
            </actions-dropdown>
          </template>
        </title-area>

        <div class="gl-grid gl-gap-3 md:gl-grid-cols-4">
          <div class="gl-pr-8 md:gl-col-span-3">
            <load-or-error-or-show :is-loading="isLoading" :error-message="errorMessage">
              <gl-tabs class="gl-mt-4" :value="tabIndex">
                <gl-tab
                  v-if="latestVersion"
                  :title="$options.i18n.tabModelCardTitle"
                  @click="goTo($options.ROUTE_DETAILS)"
                />
                <gl-tab v-if="latestVersion" @click="goTo($options.ROUTE_VERSIONS)">
                  <template #title>
                    {{ $options.i18n.tabVersionsTitle }}
                    <gl-badge class="gl-tab-counter-badge">{{ versionCount }}</gl-badge>
                  </template>
                </gl-tab>

                <router-view :model-id="model.id" :model="model" />
              </gl-tabs>
            </load-or-error-or-show>
          </div>

          <div class="gl-pt-6 md:gl-col-span-1">
            <div>
              <div class="gl-text-lg gl-font-bold">{{ $options.i18n.authorTitle }}</div>
              <div v-if="showModelAuthor" class="gl-pt-2 gl-text-gray-500">
                <gl-link
                  data-testid="sidebar-author-link"
                  class="js-user-link gl-font-bold !gl-text-gray-500"
                  :href="model.author.webUrl"
                >
                  <gl-avatar :label="model.author.name" :src="model.author.avatarUrl" :size="24" />
                  {{ model.author.name }}
                </gl-link>
              </div>
            </div>
            <div class="gl-mt-5">
              <div class="gl-text-lg gl-font-bold">{{ $options.i18n.latestVersionTitle }}</div>
              <div v-if="showModelLatestVersion" class="gl-pt-2 gl-text-gray-500">
                <gl-link
                  data-testid="sidebar-latest-version-link"
                  :href="model.latestVersion._links.showPath"
                >
                  {{ model.latestVersion.version }}
                </gl-link>
              </div>
            </div>
            <div class="gl-mt-5">
              <div class="gl-text-lg gl-font-bold">{{ $options.i18n.versionCountTitle }}</div>
              <div v-if="showCreatedDetail" class="gl-pt-2 gl-text-gray-500">
                <span data-testid="sidebar-version-count">
                  {{ versionCount }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </delete-model>
</template>
