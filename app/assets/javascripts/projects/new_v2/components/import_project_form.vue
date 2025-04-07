<script>
import { GlButton, GlFormGroup, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';
import SingleChoiceSelectorItem from '~/vue_shared/components/single_choice_selector_item.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlIcon,
    MultiStepFormTemplate,
    SingleChoiceSelector,
    SingleChoiceSelectorItem,
  },
  inject: {
    importGitlabEnabled: {
      default: false,
    },
    importGitlabImportPath: {
      default: null,
    },
    importGithubEnabled: {
      default: false,
    },
    importGithubImportPath: {
      default: null,
    },
    importBitbucketEnabled: {
      default: false,
    },
    importBitbucketImportPath: {
      default: null,
    },
    importBitbucketImportConfigured: {
      default: false,
    },
    importBitbucketDisabledMessage: {
      default: null,
    },
    importBitbucketServerEnabled: {
      default: false,
    },
    importBitbucketServerImportPath: {
      default: null,
    },
    importFogbugzEnabled: {
      default: false,
    },
    importFogbugzImportPath: {
      default: null,
    },
    importGiteaEnabled: {
      default: false,
    },
    importGiteaImportPath: {
      default: null,
    },
    importGitEnabled: {
      default: false,
    },
    importManifestEnabled: {
      default: false,
    },
    importManifestImportPath: {
      default: null,
    },
  },
  props: {
    option: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    namespace: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      selectedImport: null,
    };
  },
  computed: {
    namespaceId() {
      if (this.namespace?.id) {
        return isGid(this.namespace.id) ? getIdFromGraphQLId(this.namespace.id) : this.namespace.id;
      }
      return null;
    },
    isPersonalNamespace() {
      return this.namespace?.isPersonal ?? false;
    },
    importOptions() {
      return [
        {
          isAvailable: this.importGitlabEnabled,
          path: this.namespaceId
            ? `${this.importGitlabImportPath}?namespace_id=${this.namespaceId}`
            : this.importGitlabImportPath,
          icon: 'tanuki',
          title: s__('ProjectImport|GitLab'),
          name: 'gitlab',
          stepsTotal: 3,
        },
        {
          isAvailable: this.importGithubEnabled,
          path: this.importGithubImportPath,
          icon: 'github',
          title: s__('ProjectImport|GitHub'),
          name: 'github',
          stepsTotal: 4,
        },
        {
          isAvailable: this.importBitbucketEnabled,
          path: this.importBitbucketImportPath,
          icon: 'bitbucket',
          title: s__('ProjectImport|Bitbucket Cloud'),
          name: 'bitbucket-cloud',
          disabled: !this.importBitbucketImportConfigured,
          disabledMessage: this.importBitbucketDisabledMessage,
          stepsTotal: 4,
        },
        {
          isAvailable: this.importBitbucketServerEnabled,
          path: this.importBitbucketServerImportPath,
          icon: 'bitbucket',
          title: s__('ProjectImport|Bitbucket Server'),
          name: 'bitbucket-server',
          stepsTotal: 4,
        },
        {
          isAvailable: this.importFogbugzEnabled,
          path: this.importFogbugzImportPath,
          icon: 'bug',
          title: s__('ProjectImport|FogBugz'),
          name: 'fogbugz',
          stepsTotal: 4,
        },
        {
          isAvailable: this.importGiteaEnabled,
          path: this.importGiteaImportPath,
          icon: 'gitea',
          title: s__('ProjectImport|Gitea'),
          name: 'gitea',
          stepsTotal: 4,
        },
        {
          isAvailable: this.importManifestEnabled && !this.isPersonalNamespace,
          path: this.namespaceId
            ? `${this.importManifestImportPath}?namespace_id=${this.namespaceId}`
            : this.importManifestImportPath,
          icon: 'doc-text',
          title: s__('ProjectImport|Manifest file'),
          name: 'manifest',
          stepsTotal: 3,
        },
        {
          isAvailable: this.importGitEnabled,
          path: null,
          icon: 'link',
          title: s__('ProjectImport|Project URL'),
          name: 'url',
          stepsTotal: 3,
        },
      ];
    },
    availableImportOptions() {
      return this.importOptions.filter((option) => option.isAvailable) || [];
    },
    selectedImportPath() {
      return this.selectedImport?.path;
    },
    selectedImportStepsTotal() {
      return this.selectedImport?.stepsTotal;
    },
  },
  created() {
    [this.selectedImport] = this.availableImportOptions;
  },
  methods: {
    selectImport(name) {
      this.selectedImport = this.availableImportOptions.find((option) => option.name === name);
    },
  },
};
</script>

<template>
  <multi-step-form-template
    :title="option.title"
    :current-step="2"
    :steps-total="selectedImportStepsTotal"
  >
    <template #form>
      <gl-form-group :label="s__('ProjectsNew|Import project from')">
        <single-choice-selector :checked="selectedImport.name" @change="selectImport">
          <template v-for="item in availableImportOptions">
            <single-choice-selector-item
              :key="item.name"
              :value="item.name"
              :disabled="item.disabled"
              :disabled-message="item.disabledMessage"
            >
              <gl-icon :name="item.icon" />
              {{ item.title }}
            </single-choice-selector-item>
          </template>
        </single-choice-selector>
      </gl-form-group>
    </template>
    <template #next>
      <gl-button
        v-if="selectedImportPath"
        category="primary"
        variant="confirm"
        data-testid="import-project-next-button"
        :href="selectedImportPath"
      >
        {{ __('Next step') }}
      </gl-button>
      <gl-button
        v-else
        category="primary"
        variant="confirm"
        data-testid="import-project-next-button"
        @click="$emit('next')"
      >
        {{ __('Next step') }}
      </gl-button>
    </template>
    <template #back>
      <gl-button
        category="primary"
        variant="default"
        data-testid="import-project-back-button"
        @click="$emit('back')"
      >
        {{ __('Go back') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
