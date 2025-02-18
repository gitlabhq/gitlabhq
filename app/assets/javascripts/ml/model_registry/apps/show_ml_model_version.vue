<script>
import VueRouter from 'vue-router';
import { GlAvatar, GlTab, GlTabs, GlBadge, GlButton, GlSprintf, GlIcon, GlLink } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { setUrlFragment, visitUrlWithAlerts } from '~/lib/utils/url_utility';
import getModelVersionQuery from '~/ml/model_registry/graphql/queries/get_model_version.query.graphql';
import deleteModelVersionMutation from '~/ml/model_registry/graphql/mutations/delete_model_version.mutation.graphql';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { makeLoadVersionsErrorMessage } from '~/ml/model_registry/translations';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import ModelVersionDetail from '../components/model_version_detail.vue';
import ModelVersionPerformance from '../components/model_version_performance.vue';
import LoadOrErrorOrShow from '../components/load_or_error_or_show.vue';
import ModelVersionActionsDropdown from '../components/model_version_actions_dropdown.vue';
import ModelVersionArtifacts from '../components/model_version_artifacts.vue';
import { ROUTE_DETAILS, ROUTE_PERFORMANCE, ROUTE_ARTIFACTS } from '../constants';

const routes = [
  {
    path: '/',
    name: ROUTE_DETAILS,
    component: ModelVersionDetail,
  },
  {
    path: '/artifacts',
    name: ROUTE_ARTIFACTS,
    component: ModelVersionArtifacts,
  },
  {
    path: '/performance',
    name: ROUTE_PERFORMANCE,
    component: ModelVersionPerformance,
  },
  { path: '*', redirect: { name: ROUTE_DETAILS } },
];

export default {
  name: 'ShowMlModelVersionApp',
  components: {
    GlAvatar,
    GlButton,
    LoadOrErrorOrShow,
    ModelVersionActionsDropdown,
    TitleArea,
    GlTabs,
    GlTab,
    GlBadge,
    GlIcon,
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
  },
  router: new VueRouter({
    routes,
  }),
  mixins: [timeagoMixin],
  provide() {
    return {
      projectPath: this.projectPath,
      canWriteModelRegistry: this.canWriteModelRegistry,
      importPath: this.importPath,
      versionName: this.versionName,
      maxAllowedFileSize: this.maxAllowedFileSize,
      markdownPreviewPath: this.markdownPreviewPath,
    };
  },
  props: {
    modelId: {
      type: Number,
      required: true,
    },
    modelVersionId: {
      type: Number,
      required: true,
    },
    versionName: {
      type: String,
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
    canWriteModelRegistry: {
      type: Boolean,
      required: true,
    },
    importPath: {
      type: String,
      required: true,
    },
    modelPath: {
      type: String,
      required: true,
    },
    editModelVersionPath: {
      type: String,
      required: true,
    },
    maxAllowedFileSize: {
      type: Number,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    modelWithModelVersion: {
      query: getModelVersionQuery,
      variables() {
        return this.queryVariables;
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
      modelWithModelVersion: {},
      errorMessage: '',
    };
  },
  computed: {
    modelVersionsPath() {
      return setUrlFragment(this.modelPath, '#versions');
    },
    modelVersion() {
      return this.modelWithModelVersion?.version;
    },
    isLoading() {
      return this.$apollo.queries.modelWithModelVersion.loading;
    },
    title() {
      return `${this.modelName} / ${this.versionName}`;
    },
    queryVariables() {
      return {
        modelId: convertToGraphQLId('Ml::Model', this.modelId),
        modelVersionId: convertToGraphQLId('Ml::ModelVersion', this.modelVersionId),
      };
    },
    deletionSuccessfulAlert() {
      return {
        id: 'ml-model-version_deleted-successfully',
        message: sprintf(s__('MlModelRegistry|Model version %{versionName} deleted successfully'), {
          versionName: this.versionName,
        }),
        variant: 'success',
      };
    },
    createdMessage() {
      return s__('MlModelRegistry|Version created %{timeAgo} by %{author}');
    },
    authorId() {
      return getIdFromGraphQLId(`${this.modelVersion.author.id}`);
    },
    showCreatedDetail() {
      return this.modelVersion?.author && this.modelVersion?.createdAt;
    },
    tabIndex() {
      return routes.findIndex(({ name }) => name === this.$route.name);
    },
    showAuthor() {
      return Boolean(this.modelVersion?.author);
    },
    author() {
      return this.modelVersion?.author;
    },
    artifactsCount() {
      return this.modelVersion.artifactsCount;
    },
  },
  methods: {
    handleError(error) {
      this.errorMessage = makeLoadVersionsErrorMessage(error.message);
      Sentry.captureException(error, {
        tags: {
          vue_component: 'show_ml_model_version',
        },
      });
    },
    handleDeleteError(error) {
      Sentry.captureException(error, {
        tags: {
          vue_component: 'show_ml_model_version',
        },
      });
      createAlert({
        message: s__(
          'MlModelRegistry|Something went wrong while trying to delete the model version. Please try again later.',
        ),
        variant: VARIANT_DANGER,
      });
    },
    async deleteModelVersion() {
      try {
        const TYPENAME_MODEL_VERSION = 'Ml::ModelVersion';
        const { data } = await this.$apollo.mutate({
          mutation: deleteModelVersionMutation,
          variables: {
            id: convertToGraphQLId(TYPENAME_MODEL_VERSION, this.modelVersionId),
          },
        });

        if (data.mlModelVersionDelete?.errors?.length > 0) {
          throw data.mlModelVersionDelete.errors.join(', ');
        }

        visitUrlWithAlerts(this.modelVersionsPath, [this.deletionSuccessfulAlert]);
      } catch (error) {
        this.handleDeleteError(error);
      }
    },
    goTo(name) {
      if (name !== this.$route.name) {
        this.$router.push({ name });
      }
    },
  },
  i18n: {
    editModelVersionButtonLabel: __('Edit'),
    authorTitle: s__('MlModelRegistry|Publisher'),
    tabs: {
      modelVersionCard: s__('MlModelRegistry|Version card'),
      artifacts: s__('MlModelRegistry|Artifacts'),
      performance: s__('MlModelRegistry|Performance'),
    },
    noneText: __('None'),
  },
  ROUTE_DETAILS,
  ROUTE_ARTIFACTS,
  ROUTE_PERFORMANCE,
};
</script>

<template>
  <div>
    <div class="gl-flex gl-flex-wrap gl-justify-between gl-py-3 sm:gl-flex-nowrap">
      <div class="gl-min-w-0 gl-grow gl-flex-col">
        <title-area :title="title">
          <template #metadata-versions-count>
            <div
              v-if="showCreatedDetail"
              class="detail-page-header-body mb-3 gl-flex-wrap gl-gap-x-2"
              data-testid="metadata"
            >
              <gl-icon name="machine-learning" />
              <gl-sprintf :message="createdMessage">
                <template #timeAgo>
                  <time-ago-tooltip :time="modelVersion.createdAt" />
                </template>
                <template #author>
                  <gl-link
                    class="js-user-link gl-font-bold !gl-text-subtle"
                    :href="author.webUrl"
                    :data-user-id="authorId"
                  >
                    <span class="sm:gl-inline">{{ author.name }}</span>
                  </gl-link>
                </template>
              </gl-sprintf>
            </div>
          </template>
        </title-area>
      </div>
      <div class="gl-mt-3 gl-flex gl-items-start gl-gap-3">
        <gl-button
          v-if="canWriteModelRegistry"
          data-testid="edit-model-version-button"
          category="secondary"
          :href="editModelVersionPath"
          >{{ $options.i18n.editModelVersionButtonLabel }}</gl-button
        >
        <model-version-actions-dropdown
          :model-version="modelWithModelVersion"
          @delete-model-version="deleteModelVersion"
        />
      </div>
    </div>

    <div class="gl-grid gl-gap-3 md:gl-grid-cols-4">
      <div class="md:gl-col-span-3 md:gl-pr-8">
        <load-or-error-or-show :is-loading="isLoading" :error-message="errorMessage">
          <gl-tabs class="gl-mt-4" :value="tabIndex">
            <gl-tab
              :title="$options.i18n.tabs.modelVersionCard"
              @click="goTo($options.ROUTE_DETAILS)"
            />
            <gl-tab @click="goTo($options.ROUTE_ARTIFACTS)">
              <template #title>
                {{ $options.i18n.tabs.artifacts }}
                <gl-badge class="gl-tab-counter-badge">{{ artifactsCount }}</gl-badge>
              </template>
            </gl-tab>
            <gl-tab
              :title="$options.i18n.tabs.performance"
              @click="goTo($options.ROUTE_PERFORMANCE)"
            />
          </gl-tabs>
          <router-view :model-version="modelVersion" import-path allow-artifact-import />
        </load-or-error-or-show>
      </div>

      <div class="gl-pt-6 md:gl-col-span-1">
        <div class="gl-text-lg gl-font-bold">{{ $options.i18n.authorTitle }}</div>
        <div class="gl-mt-3 gl-text-subtle" data-testid="sidebar-author">
          <gl-link
            v-if="showAuthor"
            data-testid="sidebar-author-link"
            class="js-user-link gl-font-bold !gl-text-subtle"
            :href="author.webUrl"
          >
            <gl-avatar :label="author.name" :src="author.avatarUrl" :size="24" />
            {{ author.name }}
          </gl-link>
          <span v-else>{{ $options.i18n.noneText }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
