<script>
import {
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlCollapsibleListbox,
  GlLink,
  GlSprintf,
  GlAlert,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { isAbsolute } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  ENVIRONMENT_NEW_HELP_TEXT,
  ENVIRONMENT_EDIT_HELP_TEXT,
} from 'ee_else_ce/environments/constants';
import csrf from '~/lib/utils/csrf';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import getNamespacesQuery from '../graphql/queries/k8s_namespaces.query.graphql';
import getUserAuthorizedAgents from '../graphql/queries/user_authorized_agents.query.graphql';
import EnvironmentFluxResourceSelector from './environment_flux_resource_selector.vue';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlCollapsibleListbox,
    GlLink,
    GlSprintf,
    GlAlert,
    EnvironmentFluxResourceSelector,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    protectedEnvironmentSettingsPath: { default: '' },
    projectPath: { default: '' },
    kasTunnelUrl: { default: '' },
  },
  props: {
    environment: {
      required: true,
      type: Object,
    },
    title: {
      required: true,
      type: String,
    },
    cancelPath: {
      required: true,
      type: String,
    },
    loading: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  i18n: {
    header: __('Environments'),
    helpNewMessage: ENVIRONMENT_NEW_HELP_TEXT,
    helpEditMessage: ENVIRONMENT_EDIT_HELP_TEXT,
    nameLabel: __('Name'),
    nameFeedback: __('This field is required'),
    nameDisabledHelp: __("You cannot rename an environment after it's created."),
    nameDisabledLinkText: __('How do I rename an environment?'),
    urlLabel: __('External URL'),
    urlFeedback: __('The URL should start with http:// or https://'),
    agentLabel: s__('Environments|GitLab agent'),
    agentHelpText: s__('Environments|Select agent'),
    namespaceLabel: s__('Environments|Kubernetes namespace (optional)'),
    namespaceHelpText: s__('Environments|Select namespace'),
    save: __('Save'),
    cancel: __('Cancel'),
    reset: __('Reset'),
  },
  environmentsHelpPagePath: helpPagePath('ci/environments/index.md'),
  renamingDisabledHelpPagePath: helpPagePath('ci/environments/index.md', {
    anchor: 'rename-an-environment',
  }),
  data() {
    return {
      visited: {
        name: null,
        url: null,
      },
      userAccessAuthorizedAgents: [],
      loadingAgentsList: false,
      selectedAgentId: this.environment.clusterAgentId,
      agentSearchTerm: '',
      selectedNamespace: this.environment.kubernetesNamespace,
      k8sNamespaces: [],
      namespaceSearchTerm: '',
      kubernetesError: '',
    };
  },
  apollo: {
    k8sNamespaces: {
      query: getNamespacesQuery,
      skip() {
        return !this.showNamespaceSelector;
      },
      variables() {
        return {
          configuration: this.k8sAccessConfiguration,
        };
      },
      update(data) {
        return data?.k8sNamespaces || [];
      },
      error(error) {
        this.kubernetesError = error.message;
      },
      result(result) {
        if (!result?.error && !result.errors?.length) {
          this.kubernetesError = null;
        }
      },
    },
  },
  computed: {
    loadingNamespacesList() {
      return this.$apollo.queries.k8sNamespaces.loading;
    },
    isNameDisabled() {
      return Boolean(this.environment.id);
    },
    showEditHelp() {
      return this.isNameDisabled && Boolean(this.protectedEnvironmentSettingsPath);
    },
    valid() {
      return {
        name: this.visited.name && this.environment.name !== '',
        url: this.visited.url && isAbsolute(this.environment.externalUrl),
      };
    },
    agentsList() {
      return this.userAccessAuthorizedAgents.map((node) => {
        return {
          value: node?.agent?.id,
          text: node?.agent?.name,
        };
      });
    },
    agentDropdownToggleText() {
      if (!this.selectedAgentId) {
        return this.$options.i18n.agentHelpText;
      }
      const selectedAgentById = this.agentsList.find(
        (agent) => agent.value === this.selectedAgentId,
      );
      return selectedAgentById?.text || this.environment.clusterAgent?.name;
    },
    filteredAgentsList() {
      const lowerCasedSearchTerm = this.agentSearchTerm.toLowerCase();
      return this.agentsList.filter((item) =>
        item.text.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
    namespacesList() {
      return this.k8sNamespaces.map((item) => {
        return {
          value: item.metadata.name,
          text: item.metadata.name,
        };
      });
    },
    filteredNamespacesList() {
      const lowerCasedSearchTerm = this.namespaceSearchTerm.toLowerCase();
      return this.namespacesList.filter((item) =>
        item.text.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
    showNamespaceSelector() {
      return Boolean(this.selectedAgentId);
    },
    namespaceDropdownToggleText() {
      return this.selectedNamespace || this.$options.i18n.namespaceHelpText;
    },
    isKasFluxResourceAvailable() {
      return this.glFeatures?.fluxResourceForEnvironment;
    },
    showFluxResourceSelector() {
      return Boolean(
        this.isKasFluxResourceAvailable && this.selectedNamespace && this.selectedAgentId,
      );
    },
    k8sAccessConfiguration() {
      if (!this.showNamespaceSelector) {
        return null;
      }
      return {
        basePath: this.kasTunnelUrl,
        baseOptions: {
          headers: {
            'GitLab-Agent-Id': getIdFromGraphQLId(this.selectedAgentId),
            ...csrf.headers,
          },
          withCredentials: true,
        },
      };
    },
  },
  watch: {
    environment(change) {
      this.selectedAgentId = change.clusterAgentId;
      this.selectedNamespace = change.kubernetesNamespace;
    },
  },
  methods: {
    onChange(env) {
      this.$emit('change', env);
    },
    visit(field) {
      this.visited[field] = true;
    },
    getAgentsList() {
      this.$apollo.addSmartQuery('userAccessAuthorizedAgents', {
        variables() {
          return { projectFullPath: this.projectPath };
        },
        query: getUserAuthorizedAgents,
        update: (data) => {
          return data?.project?.userAccessAuthorizedAgents?.nodes || [];
        },
        watchLoading: (isLoading) => {
          this.loadingAgentsList = isLoading;
        },
      });
    },
    onAgentSearch(search) {
      this.agentSearchTerm = search;
    },
    onAgentChange($event) {
      this.selectedNamespace = null;
      this.onChange({
        ...this.environment,
        clusterAgentId: $event,
        kubernetesNamespace: null,
        fluxResourcePath: null,
      });
    },
    onNamespaceSearch(search) {
      this.namespaceSearchTerm = search;
    },
  },
};
</script>
<template>
  <div>
    <h1 class="page-title gl-font-size-h-display">
      {{ title }}
    </h1>
    <div class="row col-12">
      <h4 class="gl-mt-0">
        {{ $options.i18n.header }}
      </h4>
      <p class="gl-w-full">
        <gl-sprintf
          :message="showEditHelp ? $options.i18n.helpEditMessage : $options.i18n.helpNewMessage"
        >
          <template #link="{ content }">
            <gl-link
              :href="
                showEditHelp ? protectedEnvironmentSettingsPath : $options.environmentsHelpPagePath
              "
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </p>
      <gl-form
        id="new_environment"
        :aria-label="title"
        class="gl-w-full"
        @submit.prevent="$emit('submit')"
      >
        <gl-form-group
          :label="$options.i18n.nameLabel"
          label-for="environment_name"
          :state="valid.name"
          :invalid-feedback="$options.i18n.nameFeedback"
        >
          <template v-if="isNameDisabled" #description>
            {{ $options.i18n.nameDisabledHelp }}
            <gl-link :href="$options.renamingDisabledHelpPagePath" target="_blank">
              {{ $options.i18n.nameDisabledLinkText }}
            </gl-link>
          </template>
          <gl-form-input
            id="environment_name"
            :value="environment.name"
            :state="valid.name"
            :disabled="isNameDisabled"
            name="environment[name]"
            required
            @input="onChange({ ...environment, name: $event })"
            @blur="visit('name')"
          />
        </gl-form-group>
        <gl-form-group
          :label="$options.i18n.urlLabel"
          :state="valid.url"
          :invalid-feedback="$options.i18n.urlFeedback"
          label-for="environment_external_url"
        >
          <gl-form-input
            id="environment_external_url"
            :value="environment.externalUrl"
            :state="valid.url"
            name="environment[external_url]"
            type="url"
            @input="onChange({ ...environment, externalUrl: $event })"
            @blur="visit('url')"
          />
        </gl-form-group>

        <gl-form-group :label="$options.i18n.agentLabel" label-for="environment_agent">
          <gl-collapsible-listbox
            id="environment_agent"
            v-model="selectedAgentId"
            class="gl-w-full"
            data-testid="agent-selector"
            block
            :items="filteredAgentsList"
            :loading="loadingAgentsList"
            :toggle-text="agentDropdownToggleText"
            :header-text="$options.i18n.agentHelpText"
            :reset-button-label="$options.i18n.reset"
            :searchable="true"
            @shown="getAgentsList"
            @search="onAgentSearch"
            @select="onAgentChange"
            @reset="onChange({ ...environment, clusterAgentId: null })"
          />
        </gl-form-group>

        <gl-form-group
          v-if="showNamespaceSelector"
          :label="$options.i18n.namespaceLabel"
          label-for="environment_namespace"
        >
          <gl-alert v-if="kubernetesError" variant="warning" :dismissible="false" class="gl-mb-5">
            {{ kubernetesError }}
          </gl-alert>
          <gl-collapsible-listbox
            v-else
            id="environment_namespace"
            v-model="selectedNamespace"
            class="gl-w-full"
            data-testid="namespace-selector"
            block
            :items="filteredNamespacesList"
            :loading="loadingNamespacesList"
            :toggle-text="namespaceDropdownToggleText"
            :header-text="$options.i18n.namespaceHelpText"
            :reset-button-label="$options.i18n.reset"
            :searchable="true"
            @search="onNamespaceSearch"
            @select="
              onChange({ ...environment, kubernetesNamespace: $event, fluxResourcePath: null })
            "
            @reset="onChange({ ...environment, kubernetesNamespace: null })"
          />
        </gl-form-group>

        <environment-flux-resource-selector
          v-if="showFluxResourceSelector"
          :namespace="selectedNamespace"
          :configuration="k8sAccessConfiguration"
          :flux-resource-path="environment.fluxResourcePath"
          @change="onChange({ ...environment, fluxResourcePath: $event })"
        />

        <div class="gl-mr-6">
          <gl-button
            :loading="loading"
            type="submit"
            variant="confirm"
            name="commit"
            class="js-no-auto-disable"
            >{{ $options.i18n.save }}</gl-button
          >
          <gl-button :href="cancelPath">{{ $options.i18n.cancel }}</gl-button>
        </div>
      </gl-form>
    </div>
  </div>
</template>
