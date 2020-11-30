<script>
import { GlIcon, GlSprintf, GlLink, GlFormCheckbox } from '@gitlab/ui';

import settingsMixin from 'ee_else_ce/pages/projects/shared/permissions/mixins/settings_pannel_mixin';
import { s__ } from '~/locale';
import projectFeatureSetting from './project_feature_setting.vue';
import projectFeatureToggle from '~/vue_shared/components/toggle_button.vue';
import projectSettingRow from './project_setting_row.vue';
import {
  visibilityOptions,
  visibilityLevelDescriptions,
  featureAccessLevelMembers,
  featureAccessLevelEveryone,
  featureAccessLevel,
} from '../constants';
import { toggleHiddenClassBySelector } from '../external';

const PAGE_FEATURE_ACCESS_LEVEL = s__('ProjectSettings|Everyone');

export default {
  components: {
    projectFeatureSetting,
    projectFeatureToggle,
    projectSettingRow,
    GlIcon,
    GlSprintf,
    GlLink,
    GlFormCheckbox,
  },
  mixins: [settingsMixin],

  props: {
    currentSettings: {
      type: Object,
      required: true,
    },
    canDisableEmails: {
      type: Boolean,
      required: false,
      default: false,
    },
    canChangeVisibilityLevel: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowedVisibilityOptions: {
      type: Array,
      required: false,
      default: () => [
        visibilityOptions.PRIVATE,
        visibilityOptions.INTERNAL,
        visibilityOptions.PUBLIC,
      ],
    },
    lfsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    registryAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    packagesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    requirementsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    visibilityHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    lfsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    lfsObjectsExist: {
      type: Boolean,
      required: false,
      default: false,
    },
    lfsObjectsRemovalHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    registryHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    pagesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    pagesAccessControlEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    pagesAccessControlForced: {
      type: Boolean,
      required: false,
      default: false,
    },
    pagesHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    packagesHelpPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    const defaults = {
      visibilityOptions,
      visibilityLevel: visibilityOptions.PUBLIC,
      issuesAccessLevel: featureAccessLevel.EVERYONE,
      repositoryAccessLevel: featureAccessLevel.EVERYONE,
      forkingAccessLevel: featureAccessLevel.EVERYONE,
      mergeRequestsAccessLevel: featureAccessLevel.EVERYONE,
      buildsAccessLevel: featureAccessLevel.EVERYONE,
      wikiAccessLevel: featureAccessLevel.EVERYONE,
      snippetsAccessLevel: featureAccessLevel.EVERYONE,
      pagesAccessLevel: featureAccessLevel.EVERYONE,
      metricsDashboardAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
      requirementsAccessLevel: featureAccessLevel.EVERYONE,
      containerRegistryEnabled: true,
      lfsEnabled: true,
      requestAccessEnabled: true,
      highlightChangesClass: false,
      emailsDisabled: false,
      featureAccessLevelEveryone,
      featureAccessLevelMembers,
    };

    return { ...defaults, ...this.currentSettings };
  },

  computed: {
    featureAccessLevelOptions() {
      const options = [featureAccessLevelMembers];
      if (this.visibilityLevel !== visibilityOptions.PRIVATE) {
        options.push(featureAccessLevelEveryone);
      }
      return options;
    },

    repoFeatureAccessLevelOptions() {
      return this.featureAccessLevelOptions.filter(
        ([value]) => value <= this.repositoryAccessLevel,
      );
    },

    pagesFeatureAccessLevelOptions() {
      const options = [featureAccessLevelMembers];

      if (this.pagesAccessControlForced) {
        if (this.visibilityLevel === visibilityOptions.INTERNAL) {
          options.push(featureAccessLevelEveryone);
        }
      } else {
        if (this.visibilityLevel !== visibilityOptions.PRIVATE) {
          options.push(featureAccessLevelEveryone);
        }

        if (this.visibilityLevel !== visibilityOptions.PUBLIC) {
          options.push([30, PAGE_FEATURE_ACCESS_LEVEL]);
        }
      }
      return options;
    },

    metricsOptionsDropdownEnabled() {
      return this.featureAccessLevelOptions.length < 2;
    },

    repositoryEnabled() {
      return this.repositoryAccessLevel > featureAccessLevel.NOT_ENABLED;
    },

    visibilityLevelDescription() {
      return visibilityLevelDescriptions[this.visibilityLevel];
    },

    showContainerRegistryPublicNote() {
      return this.visibilityLevel === visibilityOptions.PUBLIC;
    },

    repositoryHelpText() {
      if (this.visibilityLevel === visibilityOptions.PRIVATE) {
        return s__('ProjectSettings|View and edit files in this project');
      }

      return s__(
        'ProjectSettings|View and edit files in this project. Non-project members will only have read access',
      );
    },
  },

  watch: {
    visibilityLevel(value, oldValue) {
      if (value === visibilityOptions.PRIVATE) {
        // when private, features are restricted to "only team members"
        this.issuesAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.issuesAccessLevel,
        );
        this.repositoryAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.repositoryAccessLevel,
        );
        this.mergeRequestsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.mergeRequestsAccessLevel,
        );
        this.buildsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.buildsAccessLevel,
        );
        this.wikiAccessLevel = Math.min(featureAccessLevel.PROJECT_MEMBERS, this.wikiAccessLevel);
        this.snippetsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.snippetsAccessLevel,
        );
        this.metricsDashboardAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.metricsDashboardAccessLevel,
        );
        this.requirementsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.requirementsAccessLevel,
        );
        if (this.pagesAccessLevel === featureAccessLevel.EVERYONE) {
          // When from Internal->Private narrow access for only members
          this.pagesAccessLevel = featureAccessLevel.PROJECT_MEMBERS;
        }
        this.highlightChanges();
      } else if (oldValue === visibilityOptions.PRIVATE) {
        // if changing away from private, make enabled features more permissive
        if (this.issuesAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.issuesAccessLevel = featureAccessLevel.EVERYONE;
        if (this.repositoryAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.repositoryAccessLevel = featureAccessLevel.EVERYONE;
        if (this.mergeRequestsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.mergeRequestsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.buildsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.buildsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.wikiAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.wikiAccessLevel = featureAccessLevel.EVERYONE;
        if (this.snippetsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.snippetsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.pagesAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.pagesAccessLevel = featureAccessLevel.EVERYONE;
        if (this.metricsDashboardAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.metricsDashboardAccessLevel = featureAccessLevel.EVERYONE;
        if (this.requirementsAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.requirementsAccessLevel = featureAccessLevel.EVERYONE;

        this.highlightChanges();
      }
    },

    issuesAccessLevel(value, oldValue) {
      if (value === featureAccessLevel.NOT_ENABLED)
        toggleHiddenClassBySelector('.issues-feature', true);
      else if (oldValue === featureAccessLevel.NOT_ENABLED)
        toggleHiddenClassBySelector('.issues-feature', false);
    },

    mergeRequestsAccessLevel(value, oldValue) {
      if (value === featureAccessLevel.NOT_ENABLED)
        toggleHiddenClassBySelector('.merge-requests-feature', true);
      else if (oldValue === featureAccessLevel.NOT_ENABLED)
        toggleHiddenClassBySelector('.merge-requests-feature', false);
    },
  },

  methods: {
    highlightChanges() {
      this.highlightChangesClass = true;
      this.$nextTick(() => {
        this.highlightChangesClass = false;
      });
    },

    visibilityAllowed(option) {
      return this.allowedVisibilityOptions.includes(option);
    },
  },
};
</script>

<template>
  <div>
    <div
      class="project-visibility-setting gl-border-1 gl-border-solid gl-border-gray-100 gl-py-3 gl-px-7 gl-sm-pr-5 gl-sm-pl-5"
    >
      <project-setting-row
        ref="project-visibility-settings"
        :help-path="visibilityHelpPath"
        :label="s__('ProjectSettings|Project visibility')"
      >
        <div class="project-feature-controls gl-display-flex gl-align-items-center gl-my-3 gl-mx-0">
          <div class="select-wrapper gl-flex-fill-1">
            <select
              v-model="visibilityLevel"
              :disabled="!canChangeVisibilityLevel"
              name="project[visibility_level]"
              class="form-control select-control"
              data-qa-selector="project_visibility_dropdown"
            >
              <option
                :value="visibilityOptions.PRIVATE"
                :disabled="!visibilityAllowed(visibilityOptions.PRIVATE)"
                >{{ s__('ProjectSettings|Private') }}</option
              >
              <option
                :value="visibilityOptions.INTERNAL"
                :disabled="!visibilityAllowed(visibilityOptions.INTERNAL)"
                >{{ s__('ProjectSettings|Internal') }}</option
              >
              <option
                :value="visibilityOptions.PUBLIC"
                :disabled="!visibilityAllowed(visibilityOptions.PUBLIC)"
                >{{ s__('ProjectSettings|Public') }}</option
              >
            </select>
            <gl-icon
              name="chevron-down"
              data-hidden="true"
              class="gl-absolute gl-top-3 gl-right-3 gl-text-gray-500"
            />
          </div>
        </div>
        <span class="form-text text-muted">{{ visibilityLevelDescription }}</span>
        <label v-if="visibilityLevel !== visibilityOptions.PRIVATE" class="gl-line-height-28">
          <input
            :value="requestAccessEnabled"
            type="hidden"
            name="project[request_access_enabled]"
          />
          <input v-model="requestAccessEnabled" type="checkbox" />
          {{ s__('ProjectSettings|Allow users to request access') }}
        </label>
      </project-setting-row>
    </div>
    <div
      :class="{ 'highlight-changes': highlightChangesClass }"
      class="gl-border-1 gl-border-solid gl-border-t-none gl-border-gray-100 gl-mb-5 gl-py-3 gl-px-7 gl-sm-pr-5 gl-sm-pl-5 gl-bg-gray-10"
    >
      <project-setting-row
        ref="issues-settings"
        :label="s__('ProjectSettings|Issues')"
        :help-text="s__('ProjectSettings|Lightweight issue tracking system for this project')"
      >
        <project-feature-setting
          v-model="issuesAccessLevel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][issues_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="repository-settings"
        :label="s__('ProjectSettings|Repository')"
        :help-text="repositoryHelpText"
      >
        <project-feature-setting
          v-model="repositoryAccessLevel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][repository_access_level]"
        />
      </project-setting-row>
      <div class="project-feature-setting-group gl-pl-7 gl-sm-pl-5">
        <project-setting-row
          ref="merge-request-settings"
          :label="s__('ProjectSettings|Merge requests')"
          :help-text="s__('ProjectSettings|Submit changes to be merged upstream')"
        >
          <project-feature-setting
            v-model="mergeRequestsAccessLevel"
            :options="repoFeatureAccessLevelOptions"
            :disabled-input="!repositoryEnabled"
            name="project[project_feature_attributes][merge_requests_access_level]"
          />
        </project-setting-row>
        <project-setting-row
          ref="fork-settings"
          :label="s__('ProjectSettings|Forks')"
          :help-text="
            s__('ProjectSettings|Allow users to make copies of your repository to a new project')
          "
        >
          <project-feature-setting
            v-model="forkingAccessLevel"
            :options="featureAccessLevelOptions"
            :disabled-input="!repositoryEnabled"
            name="project[project_feature_attributes][forking_access_level]"
          />
        </project-setting-row>
        <project-setting-row
          ref="pipeline-settings"
          :label="s__('ProjectSettings|Pipelines')"
          :help-text="s__('ProjectSettings|Build, test, and deploy your changes')"
        >
          <project-feature-setting
            v-model="buildsAccessLevel"
            :options="repoFeatureAccessLevelOptions"
            :disabled-input="!repositoryEnabled"
            name="project[project_feature_attributes][builds_access_level]"
          />
        </project-setting-row>
        <project-setting-row
          v-if="registryAvailable"
          ref="container-registry-settings"
          :help-path="registryHelpPath"
          :label="s__('ProjectSettings|Container registry')"
          :help-text="
            s__('ProjectSettings|Every project can have its own space to store its Docker images')
          "
        >
          <div v-if="showContainerRegistryPublicNote" class="text-muted">
            {{
              s__(
                'ProjectSettings|Note: the container registry is always visible when a project is public',
              )
            }}
          </div>
          <project-feature-toggle
            v-model="containerRegistryEnabled"
            :disabled-input="!repositoryEnabled"
            name="project[container_registry_enabled]"
          />
        </project-setting-row>
        <project-setting-row
          v-if="lfsAvailable"
          ref="git-lfs-settings"
          :help-path="lfsHelpPath"
          :label="s__('ProjectSettings|Git Large File Storage (LFS)')"
          :help-text="
            s__('ProjectSettings|Manages large files such as audio, video, and graphics files')
          "
        >
          <project-feature-toggle
            v-model="lfsEnabled"
            :disabled-input="!repositoryEnabled"
            name="project[lfs_enabled]"
          />
          <p v-if="!lfsEnabled && lfsObjectsExist">
            <gl-sprintf
              :message="
                s__(
                  'ProjectSettings|LFS objects from this repository are still available to forks. %{linkStart}How do I remove them?%{linkEnd}',
                )
              "
            >
              <template #link="{ content }">
                <span class="d-block">
                  <gl-link :href="lfsObjectsRemovalHelpPath" target="_blank">
                    {{ content }}
                  </gl-link>
                </span>
              </template>
            </gl-sprintf>
          </p>
        </project-setting-row>
        <project-setting-row
          v-if="packagesAvailable"
          ref="package-settings"
          :help-path="packagesHelpPath"
          :label="s__('ProjectSettings|Packages')"
          :help-text="
            s__('ProjectSettings|Every project can have its own space to store its packages')
          "
        >
          <project-feature-toggle
            v-model="packagesEnabled"
            :disabled-input="!repositoryEnabled"
            name="project[packages_enabled]"
          />
        </project-setting-row>
      </div>
      <project-setting-row
        v-if="requirementsAvailable"
        ref="requirements-settings"
        :label="s__('ProjectSettings|Requirements')"
        :help-text="s__('ProjectSettings|Requirements management system for this project')"
      >
        <project-feature-setting
          v-model="requirementsAccessLevel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][requirements_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="wiki-settings"
        :label="s__('ProjectSettings|Wiki')"
        :help-text="s__('ProjectSettings|Pages for project documentation')"
      >
        <project-feature-setting
          v-model="wikiAccessLevel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][wiki_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="snippet-settings"
        :label="s__('ProjectSettings|Snippets')"
        :help-text="s__('ProjectSettings|Share code pastes with others out of Git repository')"
      >
        <project-feature-setting
          v-model="snippetsAccessLevel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][snippets_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        v-if="pagesAvailable && pagesAccessControlEnabled"
        ref="pages-settings"
        :help-path="pagesHelpPath"
        :label="s__('ProjectSettings|Pages')"
        :help-text="
          s__('ProjectSettings|With GitLab Pages you can host your static websites on GitLab')
        "
      >
        <project-feature-setting
          v-model="pagesAccessLevel"
          :options="pagesFeatureAccessLevelOptions"
          name="project[project_feature_attributes][pages_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="metrics-visibility-settings"
        :label="__('Metrics Dashboard')"
        :help-text="
          s__(
            'ProjectSettings|With Metrics Dashboard you can visualize this project performance metrics',
          )
        "
      >
        <div class="project-feature-controls gl-display-flex gl-align-items-center gl-my-3 gl-mx-0">
          <div class="select-wrapper gl-flex-fill-1">
            <select
              v-model="metricsDashboardAccessLevel"
              :disabled="metricsOptionsDropdownEnabled"
              name="project[project_feature_attributes][metrics_dashboard_access_level]"
              class="form-control project-repo-select select-control"
            >
              <option
                :value="featureAccessLevelMembers[0]"
                :disabled="!visibilityAllowed(visibilityOptions.INTERNAL)"
                >{{ featureAccessLevelMembers[1] }}</option
              >
              <option
                :value="featureAccessLevelEveryone[0]"
                :disabled="!visibilityAllowed(visibilityOptions.PUBLIC)"
                >{{ featureAccessLevelEveryone[1] }}</option
              >
            </select>
            <gl-icon
              name="chevron-down"
              data-hidden="true"
              class="gl-absolute gl-top-3 gl-right-3 gl-text-gray-500"
            />
          </div>
        </div>
      </project-setting-row>
    </div>
    <project-setting-row v-if="canDisableEmails" ref="email-settings" class="mb-3">
      <label class="js-emails-disabled">
        <input :value="emailsDisabled" type="hidden" name="project[emails_disabled]" />
        <input v-model="emailsDisabled" type="checkbox" />
        {{ s__('ProjectSettings|Disable email notifications') }}
      </label>
      <span class="form-text text-muted">{{
        s__(
          'ProjectSettings|This setting will override user notification preferences for all project members.',
        )
      }}</span>
    </project-setting-row>
    <project-setting-row class="mb-3">
      <input
        :value="showDefaultAwardEmojis"
        type="hidden"
        name="project[project_setting_attributes][show_default_award_emojis]"
      />
      <gl-form-checkbox
        v-model="showDefaultAwardEmojis"
        name="project[project_setting_attributes][show_default_award_emojis]"
      >
        {{ s__('ProjectSettings|Show default award emojis') }}
        <template #help>{{
          s__(
            'ProjectSettings|When enabled, issues, merge requests, and snippets will always show thumbs-up and thumbs-down award emoji buttons.',
          )
        }}</template>
      </gl-form-checkbox>
    </project-setting-row>
  </div>
</template>
