<script>
import { GlAlert, GlLoadingIcon, GlTabs } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import PipelineGraph from '~/ci/pipeline_editor/components/graph/pipeline_graph.vue';
import { getParameterValues, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import {
  CREATE_TAB,
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_INVALID,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_VALID,
  EDITOR_APP_STATUS_LINT_UNAVAILABLE,
  MERGED_TAB,
  TAB_QUERY_PARAM,
  TABS_INDEX,
  VALIDATE_TAB,
  VALIDATE_TAB_BADGE_DISMISSED_KEY,
  VISUALIZE_TAB,
} from '../constants';
import getAppStatus from '../graphql/queries/client/app_status.query.graphql';
import CiConfigMergedPreview from './editor/ci_config_merged_preview.vue';
import CiEditorHeader from './editor/ci_editor_header.vue';
import CiValidate from './validate/ci_validate.vue';
import TextEditor from './editor/text_editor.vue';
import EditorTab from './ui/editor_tab.vue';
import WalkthroughPopover from './popovers/walkthrough_popover.vue';

export default {
  i18n: {
    new: __('NEW'),
    tabEdit: s__('Pipelines|Edit'),
    tabGraph: s__('Pipelines|Visualize'),
    tabLint: s__('Pipelines|Lint'),
    tabMergedYaml: s__('Pipelines|Full configuration'),
    tabValidate: s__('Pipelines|Validate'),
    empty: {
      visualization: s__(
        'PipelineEditor|The pipeline visualization is displayed when the CI/CD configuration file has valid syntax.',
      ),
      lint: s__(
        'PipelineEditor|The CI/CD configuration is continuously validated. Errors and warnings are displayed when the CI/CD configuration file is not empty.',
      ),
      merge: s__(
        'PipelineEditor|The full configuration view is displayed when the CI/CD configuration file has valid syntax.',
      ),
    },
  },
  errorTexts: {
    loadMergedYaml: s__('Pipelines|Could not load full configuration content'),
  },
  query: {
    TAB_QUERY_PARAM,
  },
  tabConstants: {
    CREATE_TAB,
    MERGED_TAB,
    VALIDATE_TAB,
    VISUALIZE_TAB,
  },
  components: {
    CiConfigMergedPreview,
    CiEditorHeader,
    CiValidate,
    EditorTab,
    GlAlert,
    GlLoadingIcon,
    GlTabs,
    PipelineGraph,
    TextEditor,
    WalkthroughPopover,
  },
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    ciFileContent: {
      type: String,
      required: true,
    },
    commitSha: {
      type: String,
      required: false,
      default: '',
    },
    currentTab: {
      type: String,
      required: true,
    },
    showHelpDrawer: {
      type: Boolean,
      required: true,
    },
    showJobAssistantDrawer: {
      type: Boolean,
      required: true,
    },
    isNewCiConfigFile: {
      type: Boolean,
      required: true,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    appStatus: {
      query: getAppStatus,
      update(data) {
        return data.app.status;
      },
    },
  },
  data() {
    return {
      showValidateNewBadge: false,
    };
  },
  computed: {
    isMergedYamlAvailable() {
      return this.ciConfigData?.mergedYaml;
    },
    isEmpty() {
      return this.appStatus === EDITOR_APP_STATUS_EMPTY;
    },
    isInvalid() {
      return this.appStatus === EDITOR_APP_STATUS_INVALID;
    },
    isLintUnavailable() {
      return this.appStatus === EDITOR_APP_STATUS_LINT_UNAVAILABLE;
    },
    isValid() {
      return this.appStatus === EDITOR_APP_STATUS_VALID;
    },
    isLoading() {
      return this.appStatus === EDITOR_APP_STATUS_LOADING;
    },
    validateTabBadgeTitle() {
      if (this.showValidateNewBadge) {
        return this.$options.i18n.new;
      }

      return '';
    },
  },
  mounted() {
    this.showValidateNewBadge = !JSON.parse(localStorage.getItem(VALIDATE_TAB_BADGE_DISMISSED_KEY));
  },
  created() {
    const [tabQueryParam] = getParameterValues(TAB_QUERY_PARAM);
    const tabName = Object.keys(TABS_INDEX)[tabQueryParam];

    if (tabName) {
      this.setDefaultTab(tabName);
    }
  },
  methods: {
    setCurrentTab(tabName) {
      if (this.currentTab === VALIDATE_TAB) {
        localStorage.setItem(VALIDATE_TAB_BADGE_DISMISSED_KEY, 'true');
        this.showValidateNewBadge = false;
      }

      this.$emit('set-current-tab', tabName);
    },
    setDefaultTab(tabName) {
      // We associate tab name with the index so that we can use tab name
      // in other part of the app and load the corresponding tab closer to the
      // actual component using a hash that binds the name to the indexes.
      // This also means that if we ever changed tab order, we would justs need to
      // update `TABS_INDEX` hash instead of all the instances in the app
      // where we used the individual indexes
      const newUrl = setUrlParams({ [TAB_QUERY_PARAM]: TABS_INDEX[tabName] });

      this.setCurrentTab(tabName);
      updateHistory({ url: newUrl, title: document.title, replace: true });
    },
  },
};
</script>
<template>
  <gl-tabs
    class="file-editor gl-mb-3"
    data-testid="file-editor-container"
    :query-param-name="$options.query.TAB_QUERY_PARAM"
    sync-active-tab-with-query-params
  >
    <editor-tab
      class="gl-mb-3"
      title-link-class="js-walkthrough-popover-target"
      :title="$options.i18n.tabEdit"
      lazy
      data-testid="editor-tab"
      @click="setCurrentTab($options.tabConstants.CREATE_TAB)"
    >
      <walkthrough-popover v-if="isNewCiConfigFile" v-on="$listeners" />
      <ci-editor-header
        :show-help-drawer="showHelpDrawer"
        :show-job-assistant-drawer="showJobAssistantDrawer"
        v-on="$listeners"
      />
      <text-editor :commit-sha="commitSha" :value="ciFileContent" v-on="$listeners" />
    </editor-tab>
    <editor-tab
      class="gl-mb-3"
      :empty-message="$options.i18n.empty.visualization"
      :is-empty="isEmpty"
      :is-invalid="isInvalid"
      :is-unavailable="isLintUnavailable"
      :keep-component-mounted="false"
      :title="$options.i18n.tabGraph"
      lazy
      data-testid="visualization-tab"
      @click="setCurrentTab($options.tabConstants.VISUALIZE_TAB)"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <pipeline-graph v-else :pipeline-data="ciConfigData" />
    </editor-tab>
    <editor-tab
      class="gl-mb-3"
      data-testid="validate-tab"
      :badge-title="validateTabBadgeTitle"
      :title="$options.i18n.tabValidate"
      @click="setCurrentTab($options.tabConstants.VALIDATE_TAB)"
    >
      <ci-validate :ci-file-content="ciFileContent" />
    </editor-tab>
    <editor-tab
      class="gl-mb-3"
      :empty-message="$options.i18n.empty.merge"
      :keep-component-mounted="false"
      :is-empty="isEmpty"
      :is-unavailable="isLintUnavailable"
      :title="$options.i18n.tabMergedYaml"
      lazy
      data-testid="merged-tab"
      @click="setCurrentTab($options.tabConstants.MERGED_TAB)"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <gl-alert v-else-if="!isMergedYamlAvailable" variant="danger" :dismissible="false">
        {{ $options.errorTexts.loadMergedYaml }}
      </gl-alert>
      <ci-config-merged-preview v-else :ci-config-data="ciConfigData" v-on="$listeners" />
    </editor-tab>
  </gl-tabs>
</template>
