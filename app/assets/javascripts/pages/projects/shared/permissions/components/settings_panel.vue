<script>
import { GlButton, GlIcon, GlSprintf, GlLink, GlFormCheckbox, GlToggle } from '@gitlab/ui';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import settingsMixin from 'ee_else_ce/pages/projects/shared/permissions/mixins/settings_pannel_mixin';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__ } from '~/locale';
import {
  visibilityOptions,
  visibilityLevelDescriptions,
  featureAccessLevelMembers,
  featureAccessLevelEveryone,
  featureAccessLevel,
  CVE_ID_REQUEST_BUTTON_I18N,
  featureAccessLevelDescriptions,
} from '../constants';
import { toggleHiddenClassBySelector } from '../external';
import projectFeatureSetting from './project_feature_setting.vue';
import projectSettingRow from './project_setting_row.vue';

const FEATURE_ACCESS_LEVEL_ANONYMOUS = [30, s__('ProjectSettings|Everyone')];

export default {
  i18n: {
    ...CVE_ID_REQUEST_BUTTON_I18N,
    analyticsLabel: s__('ProjectSettings|Analytics'),
    containerRegistryLabel: s__('ProjectSettings|Container registry'),
    forksLabel: s__('ProjectSettings|Forks'),
    issuesLabel: s__('ProjectSettings|Issues'),
    lfsLabel: s__('ProjectSettings|Git Large File Storage (LFS)'),
    mergeRequestsLabel: s__('ProjectSettings|Merge requests'),
    operationsLabel: s__('ProjectSettings|Operations'),
    packagesHelpText: s__(
      'ProjectSettings|Every project can have its own space to store its packages. Note: The Package Registry is always visible when a project is public.',
    ),
    packageRegistryHelpText: s__(
      'ProjectSettings|Every project can have its own space to store its packages.',
    ),
    packagesLabel: s__('ProjectSettings|Packages'),
    packageRegistryLabel: s__('ProjectSettings|Package registry'),
    pagesLabel: s__('ProjectSettings|Pages'),
    ciCdLabel: __('CI/CD'),
    repositoryLabel: s__('ProjectSettings|Repository'),
    requirementsLabel: s__('ProjectSettings|Requirements'),
    securityAndComplianceLabel: s__('ProjectSettings|Security & Compliance'),
    snippetsLabel: s__('ProjectSettings|Snippets'),
    wikiLabel: s__('ProjectSettings|Wiki'),
    pucWarningLabel: s__('ProjectSettings|Warn about Potentially Unwanted Characters'),
    pucWarningHelpText: s__(
      'ProjectSettings|Highlight the usage of hidden unicode characters. These have innocent uses for right-to-left languages, but can also be used in potential exploits.',
    ),
    confirmButtonText: __('Save changes'),
  },

  components: {
    projectFeatureSetting,
    projectSettingRow,
    GlButton,
    GlIcon,
    GlSprintf,
    GlLink,
    GlFormCheckbox,
    GlToggle,
    ConfirmDanger,
  },
  mixins: [settingsMixin, glFeatureFlagsMixin()],

  props: {
    requestCveAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    issuesHelpPath: {
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
    cveIdRequestHelpPath: {
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
    confirmationPhrase: {
      type: String,
      required: true,
    },
    showVisibilityConfirmModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    membersPagePath: {
      type: String,
      required: true,
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
      packageRegistryAccessLevel: featureAccessLevel.EVERYONE,
      buildsAccessLevel: featureAccessLevel.EVERYONE,
      wikiAccessLevel: featureAccessLevel.EVERYONE,
      snippetsAccessLevel: featureAccessLevel.EVERYONE,
      pagesAccessLevel: featureAccessLevel.EVERYONE,
      metricsDashboardAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
      analyticsAccessLevel: featureAccessLevel.EVERYONE,
      requirementsAccessLevel: featureAccessLevel.EVERYONE,
      securityAndComplianceAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
      operationsAccessLevel: featureAccessLevel.EVERYONE,
      containerRegistryAccessLevel: featureAccessLevel.EVERYONE,
      warnAboutPotentiallyUnwantedCharacters: true,
      lfsEnabled: true,
      requestAccessEnabled: true,
      enforceAuthChecksOnUploads: true,
      highlightChangesClass: false,
      emailsDisabled: false,
      cveIdRequestEnabled: true,
      featureAccessLevelEveryone,
      featureAccessLevelMembers,
      featureAccessLevel,
      featureAccessLevelDescriptions,
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

    operationsFeatureAccessLevelOptions() {
      return this.featureAccessLevelOptions.filter(
        ([value]) => value <= this.operationsAccessLevel,
      );
    },

    packageRegistryFeatureAccessLevelOptions() {
      const options = [FEATURE_ACCESS_LEVEL_ANONYMOUS];

      if (this.visibilityLevel === visibilityOptions.PRIVATE) {
        options.unshift(featureAccessLevelMembers);
      } else if (this.visibilityLevel === visibilityOptions.INTERNAL) {
        options.unshift(featureAccessLevelEveryone);
      }

      return options;
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
          options.push(FEATURE_ACCESS_LEVEL_ANONYMOUS);
        }
      }
      return options;
    },

    operationsEnabled() {
      return this.operationsAccessLevel > featureAccessLevel.NOT_ENABLED;
    },

    repositoryEnabled() {
      return this.repositoryAccessLevel > featureAccessLevel.NOT_ENABLED;
    },

    visibilityLevelDescription() {
      return visibilityLevelDescriptions[this.visibilityLevel];
    },

    showContainerRegistryPublicNote() {
      return (
        this.visibilityLevel === visibilityOptions.PUBLIC &&
        this.containerRegistryAccessLevel === featureAccessLevel.EVERYONE
      );
    },

    repositoryHelpText() {
      if (this.visibilityLevel === visibilityOptions.PRIVATE) {
        return s__('ProjectSettings|View and edit files in this project.');
      }

      return s__(
        'ProjectSettings|View and edit files in this project. Non-project members have only read access.',
      );
    },
    cveIdRequestIsDisabled() {
      return this.visibilityLevel !== visibilityOptions.PUBLIC;
    },
    isVisibilityReduced() {
      return (
        this.showVisibilityConfirmModal &&
        this.visibilityLevel < this.currentSettings.visibilityLevel
      );
    },
    packageRegistryAccessLevelEnabled() {
      return this.glFeatures.packageRegistryAccessLevel;
    },
    showAdditonalSettings() {
      if (this.glFeatures.enforceAuthChecksOnUploads) {
        return true;
      }

      return this.visibilityLevel !== this.visibilityOptions.PRIVATE;
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
        if (this.packageRegistryAccessLevelEnabled) {
          if (
            this.packageRegistryAccessLevel === featureAccessLevel.EVERYONE ||
            (this.packageRegistryAccessLevel > featureAccessLevel.EVERYONE &&
              oldValue === visibilityOptions.PUBLIC)
          ) {
            this.packageRegistryAccessLevel = featureAccessLevel.PROJECT_MEMBERS;
          }
        }
        this.wikiAccessLevel = Math.min(featureAccessLevel.PROJECT_MEMBERS, this.wikiAccessLevel);
        this.snippetsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.snippetsAccessLevel,
        );
        this.metricsDashboardAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.metricsDashboardAccessLevel,
        );
        this.analyticsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.analyticsAccessLevel,
        );
        this.requirementsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.requirementsAccessLevel,
        );
        this.securityAndComplianceAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.securityAndComplianceAccessLevel,
        );
        this.operationsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.operationsAccessLevel,
        );
        this.containerRegistryAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.containerRegistryAccessLevel,
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
        if (
          this.packageRegistryAccessLevelEnabled &&
          this.packageRegistryAccessLevel === featureAccessLevel.PROJECT_MEMBERS
        ) {
          this.packageRegistryAccessLevel = Math.min(
            ...this.packageRegistryFeatureAccessLevelOptions.map((option) => option[0]),
          );
        }
        if (this.buildsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.buildsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.wikiAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.wikiAccessLevel = featureAccessLevel.EVERYONE;
        if (this.snippetsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.snippetsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.pagesAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.pagesAccessLevel = featureAccessLevel.EVERYONE;
        if (this.analyticsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.analyticsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.metricsDashboardAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.metricsDashboardAccessLevel = featureAccessLevel.EVERYONE;
        if (this.requirementsAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.requirementsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.operationsAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.operationsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.containerRegistryAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.containerRegistryAccessLevel = featureAccessLevel.EVERYONE;

        this.highlightChanges();
      } else if (this.packageRegistryAccessLevelEnabled) {
        if (
          value === visibilityOptions.PUBLIC &&
          this.packageRegistryAccessLevel === featureAccessLevel.EVERYONE
        ) {
          // eslint-disable-next-line prefer-destructuring
          this.packageRegistryAccessLevel = FEATURE_ACCESS_LEVEL_ANONYMOUS[0];
        } else if (
          value === visibilityOptions.INTERNAL &&
          this.packageRegistryAccessLevel === FEATURE_ACCESS_LEVEL_ANONYMOUS[0]
        ) {
          this.packageRegistryAccessLevel = featureAccessLevel.EVERYONE;
        }
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

    operationsAccessLevel(value, oldValue) {
      if (value < oldValue) {
        // sub-features cannot have more permissive access level
        this.metricsDashboardAccessLevel = Math.min(this.metricsDashboardAccessLevel, value);
      } else if (oldValue === 0) {
        this.metricsDashboardAccessLevel = value;
      }
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
        :help-text="
          s__('ProjectSettings|Manage who can see the project in the public access directory.')
        "
      >
        <div class="project-feature-controls gl-display-flex gl-align-items-center gl-my-3 gl-mx-0">
          <div class="select-wrapper gl-flex-grow-1">
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
              >
                {{ s__('ProjectSettings|Private') }}
              </option>
              <option
                :value="visibilityOptions.INTERNAL"
                :disabled="!visibilityAllowed(visibilityOptions.INTERNAL)"
              >
                {{ s__('ProjectSettings|Internal') }}
              </option>
              <option
                :value="visibilityOptions.PUBLIC"
                :disabled="!visibilityAllowed(visibilityOptions.PUBLIC)"
              >
                {{ s__('ProjectSettings|Public') }}
              </option>
            </select>
            <gl-icon
              name="chevron-down"
              data-hidden="true"
              class="gl-absolute gl-top-3 gl-right-3 gl-text-gray-500"
            />
          </div>
        </div>
        <span
          v-if="!visibilityAllowed(visibilityLevel)"
          class="gl-display-block gl-text-gray-500 gl-mt-2"
          >{{
            s__(
              'ProjectSettings|Visibility options for this fork are limited by the current visibility of the source project.',
            )
          }}</span
        >
        <span class="gl-display-block gl-text-gray-500 gl-mt-2">
          <gl-sprintf :message="visibilityLevelDescription">
            <template #membersPageLink="{ content }">
              <gl-link class="gl-link" :href="membersPagePath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </span>
        <div v-if="showAdditonalSettings" class="gl-mt-4">
          <strong class="gl-display-block">{{ s__('ProjectSettings|Additional options') }}</strong>
          <label
            v-if="visibilityLevel !== visibilityOptions.PRIVATE"
            class="gl-line-height-28 gl-font-weight-normal gl-mb-0"
          >
            <input
              :value="requestAccessEnabled"
              type="hidden"
              name="project[request_access_enabled]"
            />
            <input v-model="requestAccessEnabled" type="checkbox" />
            {{ s__('ProjectSettings|Users can request access') }}
          </label>
          <label
            v-if="
              visibilityLevel !== visibilityOptions.PUBLIC && glFeatures.enforceAuthChecksOnUploads
            "
            class="gl-line-height-28 gl-font-weight-normal gl-display-block gl-mb-0"
          >
            <input
              :value="enforceAuthChecksOnUploads"
              type="hidden"
              name="project[project_setting_attributes][enforce_auth_checks_on_uploads]"
            />
            <input v-model="enforceAuthChecksOnUploads" type="checkbox" />
            {{ s__('ProjectSettings|Require authentication to view media files') }}
            <span class="gl-text-gray-500 gl-display-block gl-ml-5 gl-mt-n3">{{
              s__('ProjectSettings|Prevents direct linking to potentially sensitive media files')
            }}</span>
          </label>
        </div>
      </project-setting-row>
    </div>
    <div
      :class="{ 'highlight-changes': highlightChangesClass }"
      class="gl-border-1 gl-border-solid gl-border-t-none gl-border-gray-100 gl-mb-5 gl-py-3 gl-px-7 gl-sm-pr-5 gl-sm-pl-5 gl-bg-gray-10"
    >
      <project-setting-row
        ref="issues-settings"
        :help-path="issuesHelpPath"
        :label="$options.i18n.issuesLabel"
        :help-text="
          s__(
            'ProjectSettings|Flexible tool to collaboratively develop ideas and plan work in this project.',
          )
        "
      >
        <project-feature-setting
          v-model="issuesAccessLevel"
          :label="$options.i18n.issuesLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][issues_access_level]"
        />
        <project-setting-row
          v-if="requestCveAvailable"
          :help-path="cveIdRequestHelpPath"
          :help-text="$options.i18n.cve_request_toggle_label"
        >
          <gl-toggle
            v-model="cveIdRequestEnabled"
            class="gl-my-2"
            :disabled="cveIdRequestIsDisabled"
            :label="$options.i18n.cve_request_toggle_label"
            label-position="hidden"
            name="project[project_setting_attributes][cve_id_request_enabled]"
            data-testid="cve_id_request_toggle"
          />
        </project-setting-row>
      </project-setting-row>
      <project-setting-row
        ref="repository-settings"
        :label="$options.i18n.repositoryLabel"
        :help-text="repositoryHelpText"
      >
        <project-feature-setting
          v-model="repositoryAccessLevel"
          :label="$options.i18n.repositoryLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][repository_access_level]"
        />
      </project-setting-row>
      <div class="project-feature-setting-group gl-pl-7 gl-sm-pl-5">
        <project-setting-row
          ref="merge-request-settings"
          :label="$options.i18n.mergeRequestsLabel"
          :help-text="s__('ProjectSettings|Submit changes to be merged upstream.')"
        >
          <project-feature-setting
            v-model="mergeRequestsAccessLevel"
            :label="$options.i18n.mergeRequestsLabel"
            :options="repoFeatureAccessLevelOptions"
            :disabled-input="!repositoryEnabled"
            name="project[project_feature_attributes][merge_requests_access_level]"
          />
        </project-setting-row>
        <project-setting-row
          ref="fork-settings"
          :label="$options.i18n.forksLabel"
          :help-text="s__('ProjectSettings|Users can copy the repository to a new project.')"
        >
          <project-feature-setting
            v-model="forkingAccessLevel"
            :label="$options.i18n.forksLabel"
            :options="featureAccessLevelOptions"
            :disabled-input="!repositoryEnabled"
            name="project[project_feature_attributes][forking_access_level]"
          />
        </project-setting-row>
        <project-setting-row
          v-if="lfsAvailable"
          ref="git-lfs-settings"
          :help-path="lfsHelpPath"
          :label="$options.i18n.lfsLabel"
          :help-text="
            s__('ProjectSettings|Manages large files such as audio, video, and graphics files.')
          "
        >
          <gl-toggle
            v-model="lfsEnabled"
            class="gl-my-2"
            :disabled="!repositoryEnabled"
            :label="$options.i18n.lfsLabel"
            label-position="hidden"
            name="project[lfs_enabled]"
          />
          <p v-if="!lfsEnabled && lfsObjectsExist">
            <gl-sprintf
              :message="
                s__(
                  'ProjectSettings|LFS objects from this repository are available to forks. %{linkStart}How do I remove them?%{linkEnd}',
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
          v-if="packagesAvailable && !packageRegistryAccessLevelEnabled"
          ref="package-settings"
          :help-path="packagesHelpPath"
          :label="$options.i18n.packagesLabel"
          :help-text="$options.i18n.packagesHelpText"
        >
          <gl-toggle
            v-model="packagesEnabled"
            class="gl-my-2"
            :disabled="!repositoryEnabled"
            :label="$options.i18n.packagesLabel"
            label-position="hidden"
            name="project[packages_enabled]"
          />
        </project-setting-row>
        <project-setting-row
          ref="pipeline-settings"
          :label="$options.i18n.ciCdLabel"
          :help-text="s__('ProjectSettings|Build, test, and deploy your changes.')"
        >
          <project-feature-setting
            v-model="buildsAccessLevel"
            :label="$options.i18n.ciCdLabel"
            :options="repoFeatureAccessLevelOptions"
            :disabled-input="!repositoryEnabled"
            name="project[project_feature_attributes][builds_access_level]"
          />
        </project-setting-row>
      </div>
      <project-setting-row
        v-if="registryAvailable"
        ref="container-registry-settings"
        :help-path="registryHelpPath"
        :label="$options.i18n.containerRegistryLabel"
        :help-text="
          s__('ProjectSettings|Every project can have its own space to store its Docker images')
        "
      >
        <div v-if="showContainerRegistryPublicNote" class="text-muted">
          <gl-sprintf
            :message="
              s__(
                `ProjectSettings|Note: The container registry is always visible when a project is public and the container registry is set to '%{access_level_description}'`,
              )
            "
          >
            <template #access_level_description>{{
              featureAccessLevelDescriptions[featureAccessLevel.EVERYONE]
            }}</template>
          </gl-sprintf>
        </div>
        <project-feature-setting
          v-model="containerRegistryAccessLevel"
          :options="featureAccessLevelOptions"
          :label="$options.i18n.containerRegistryLabel"
          name="project[project_feature_attributes][container_registry_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="analytics-settings"
        :label="$options.i18n.analyticsLabel"
        :help-text="s__('ProjectSettings|View project analytics.')"
      >
        <project-feature-setting
          v-model="analyticsAccessLevel"
          :label="$options.i18n.analyticsLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][analytics_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        v-if="requirementsAvailable"
        ref="requirements-settings"
        :label="$options.i18n.requirementsLabel"
        :help-text="s__('ProjectSettings|Requirements management system.')"
      >
        <project-feature-setting
          v-model="requirementsAccessLevel"
          :label="$options.i18n.requirementsLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][requirements_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        :label="$options.i18n.securityAndComplianceLabel"
        :help-text="s__('ProjectSettings|Security & Compliance for this project')"
      >
        <project-feature-setting
          v-model="securityAndComplianceAccessLevel"
          :label="$options.i18n.securityAndComplianceLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][security_and_compliance_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="wiki-settings"
        :label="$options.i18n.wikiLabel"
        :help-text="s__('ProjectSettings|Pages for project documentation.')"
      >
        <project-feature-setting
          v-model="wikiAccessLevel"
          :label="$options.i18n.wikiLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][wiki_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="snippet-settings"
        :label="$options.i18n.snippetsLabel"
        :help-text="s__('ProjectSettings|Share code with others outside the project.')"
      >
        <project-feature-setting
          v-model="snippetsAccessLevel"
          :label="$options.i18n.snippetsLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][snippets_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        v-if="packageRegistryAccessLevelEnabled && packagesAvailable"
        :help-path="packagesHelpPath"
        :label="$options.i18n.packageRegistryLabel"
        :help-text="$options.i18n.packageRegistryHelpText"
        data-testid="package-registry-access-level"
      >
        <project-feature-setting
          v-model="packageRegistryAccessLevel"
          :label="$options.i18n.packageRegistryLabel"
          :options="packageRegistryFeatureAccessLevelOptions"
          name="project[project_feature_attributes][package_registry_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        v-if="pagesAvailable && pagesAccessControlEnabled"
        ref="pages-settings"
        :help-path="pagesHelpPath"
        :label="$options.i18n.pagesLabel"
        :help-text="
          s__('ProjectSettings|With GitLab Pages you can host your static websites on GitLab.')
        "
      >
        <project-feature-setting
          v-model="pagesAccessLevel"
          :label="$options.i18n.pagesLabel"
          :options="pagesFeatureAccessLevelOptions"
          name="project[project_feature_attributes][pages_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="operations-settings"
        :label="$options.i18n.operationsLabel"
        :help-text="
          s__('ProjectSettings|Configure your project resources and monitor their health.')
        "
      >
        <project-feature-setting
          v-model="operationsAccessLevel"
          :label="$options.i18n.operationsLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][operations_access_level]"
        />
      </project-setting-row>
      <div class="project-feature-setting-group gl-pl-7 gl-sm-pl-5">
        <project-setting-row
          ref="metrics-visibility-settings"
          :label="__('Metrics Dashboard')"
          :help-text="s__('ProjectSettings|Visualize the project\'s performance metrics.')"
        >
          <project-feature-setting
            v-model="metricsDashboardAccessLevel"
            :show-toggle="false"
            :options="operationsFeatureAccessLevelOptions"
            name="project[project_feature_attributes][metrics_dashboard_access_level]"
          />
        </project-setting-row>
      </div>
    </div>
    <project-setting-row v-if="canDisableEmails" ref="email-settings" class="mb-3">
      <label class="js-emails-disabled">
        <input :value="emailsDisabled" type="hidden" name="project[emails_disabled]" />
        <input v-model="emailsDisabled" type="checkbox" />
        {{ s__('ProjectSettings|Disable email notifications') }}
      </label>
      <span class="form-text text-muted">{{
        s__('ProjectSettings|Override user notification preferences for all project members.')
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
            'ProjectSettings|Always show thumbs-up and thumbs-down award emoji buttons on issues, merge requests, and snippets.',
          )
        }}</template>
      </gl-form-checkbox>
    </project-setting-row>
    <project-setting-row class="gl-mb-5">
      <input
        :value="warnAboutPotentiallyUnwantedCharacters"
        type="hidden"
        name="project[project_setting_attributes][warn_about_potentially_unwanted_characters]"
      />
      <gl-form-checkbox
        v-model="warnAboutPotentiallyUnwantedCharacters"
        name="project[project_setting_attributes][warn_about_potentially_unwanted_characters]"
      >
        {{ $options.i18n.pucWarningLabel }}
        <template #help>{{ $options.i18n.pucWarningHelpText }}</template>
      </gl-form-checkbox>
    </project-setting-row>
    <confirm-danger
      v-if="isVisibilityReduced"
      button-variant="confirm"
      :disabled="false"
      :phrase="confirmationPhrase"
      :button-text="$options.i18n.confirmButtonText"
      data-testid="project-features-save-button"
      @confirm="$emit('confirm')"
    />
    <gl-button
      v-else
      type="submit"
      variant="confirm"
      data-testid="project-features-save-button"
      data-qa-selector="visibility_features_permissions_save_button"
    >
      {{ $options.i18n.confirmButtonText }}
    </gl-button>
  </div>
</template>
