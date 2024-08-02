<script>
import { GlButton, GlIcon, GlSprintf, GlLink, GlFormCheckbox, GlToggle } from '@gitlab/ui';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import settingsMixin from 'ee_else_ce/pages/projects/shared/permissions/mixins/settings_pannel_mixin';
import { __, s__ } from '~/locale';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
} from '~/visibility_level/constants';
import {
  visibilityLevelDescriptions,
  featureAccessLevelMembers,
  featureAccessLevelEveryone,
  featureAccessLevel,
  CVE_ID_REQUEST_BUTTON_I18N,
  featureAccessLevelDescriptions,
  modelExperimentsHelpPath,
  modelRegistryHelpPath,
  duoHelpPath,
} from '../constants';
import { toggleHiddenClassBySelector } from '../external';
import ProjectFeatureSetting from './project_feature_setting.vue';
import ProjectSettingRow from './project_setting_row.vue';
import CiCatalogSettings from './ci_catalog_settings.vue';

const FEATURE_ACCESS_LEVEL_ANONYMOUS = [30, s__('ProjectSettings|Everyone')];

const PACKAGE_REGISTRY_ACCESS_LEVEL_DEFAULT_BY_PROJECT_VISIBILITY = {
  [VISIBILITY_LEVEL_PRIVATE_INTEGER]: featureAccessLevel.PROJECT_MEMBERS,
  [VISIBILITY_LEVEL_INTERNAL_INTEGER]: featureAccessLevel.EVERYONE,
  [VISIBILITY_LEVEL_PUBLIC_INTEGER]: FEATURE_ACCESS_LEVEL_ANONYMOUS[0],
};

export default {
  i18n: {
    ...CVE_ID_REQUEST_BUTTON_I18N,
    analyticsLabel: s__('ProjectSettings|Analytics'),
    containerRegistryLabel: s__('ProjectSettings|Container registry'),
    ciCdLabel: __('CI/CD'),
    forksLabel: s__('ProjectSettings|Forks'),
    issuesLabel: s__('ProjectSettings|Issues'),
    lfsLabel: s__('ProjectSettings|Git Large File Storage (LFS)'),
    mergeRequestsLabel: s__('ProjectSettings|Merge requests'),
    environmentsLabel: s__('ProjectSettings|Environments'),
    environmentsHelpText: s__(
      'ProjectSettings|Every project can make deployments to environments either via CI/CD or API calls. Non-project members have read-only access.',
    ),
    featureFlagsLabel: s__('ProjectSettings|Feature flags'),
    featureFlagsHelpText: s__(
      'ProjectSettings|Roll out new features without redeploying with feature flags.',
    ),
    infrastructureLabel: s__('ProjectSettings|Infrastructure'),
    infrastructureHelpText: s__('ProjectSettings|Configure your infrastructure.'),
    monitorLabel: s__('ProjectSettings|Monitor'),
    packageRegistryHelpText: s__('ProjectSettings|Publish, store, and view packages in a project.'),
    packageRegistryForEveryoneHelpText: s__(
      'ProjectSettings|Anyone can pull packages with a package manager API.',
    ),
    packageRegistryLabel: s__('ProjectSettings|Package registry'),
    packageRegistryForEveryoneLabel: s__(
      'ProjectSettings|Allow anyone to pull from Package Registry',
    ),
    modelExperimentsLabel: s__('ProjectSettings|Model experiments'),
    modelExperimentsHelpText: s__(
      'ProjectSettings|Track machine learning model experiments and artifacts.',
    ),
    modelRegistryLabel: s__('ProjectSettings|Model registry'),
    modelRegistryHelpText: s__('ProjectSettings|Manage machine learning models.'),
    pagesLabel: s__('ProjectSettings|Pages'),
    repositoryLabel: s__('ProjectSettings|Repository'),
    requirementsLabel: s__('ProjectSettings|Requirements'),
    releasesLabel: s__('ProjectSettings|Releases'),
    releasesHelpText: s__(
      'ProjectSettings|Combine git tags with release notes, release evidence, and assets to create a release.',
    ),
    duoLabel: s__('ProjectSettings|GitLab Duo'),
    duoHelpText: s__('ProjectSettings|Use AI-powered features in this project.'),
    securityAndComplianceLabel: s__('ProjectSettings|Security and compliance'),
    snippetsLabel: s__('ProjectSettings|Snippets'),
    wikiLabel: s__('ProjectSettings|Wiki'),
    pucWarningLabel: s__('ProjectSettings|Warn about Potentially Unwanted Characters'),
    pucWarningHelpText: s__(
      'ProjectSettings|Highlight the usage of hidden unicode characters. These have innocent uses for right-to-left languages, but can also be used in potential exploits.',
    ),
    confirmButtonText: __('Save changes'),
    emailsLabel: s__('ProjectSettings|Email notifications'),
    showDiffPreviewLabel: s__('ProjectSettings|Include diff previews'),
    showDiffPreviewHelpText: s__(
      'ProjectSettings|Emails are not encrypted. Concerned administrators may want to disable diff previews.',
    ),
  },
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
  modelExperimentsHelpPath,
  modelRegistryHelpPath,
  duoHelpPath,
  components: {
    CiCatalogSettings,
    ProjectFeatureSetting,
    ProjectSettingRow,
    GlButton,
    GlIcon,
    GlSprintf,
    GlLink,
    GlFormCheckbox,
    GlToggle,
    ConfirmDanger,
    OtherProjectSettings: () =>
      import(
        'jh_component/pages/projects/shared/permissions/components/other_project_settings.vue'
      ),
  },
  mixins: [settingsMixin, glFeatureFlagMixin()],
  props: {
    requestCveAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    canAddCatalogResource: {
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
    canSetDiffPreviewInEmail: {
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
        VISIBILITY_LEVEL_PRIVATE_INTEGER,
        VISIBILITY_LEVEL_INTERNAL_INTEGER,
        VISIBILITY_LEVEL_PUBLIC_INTEGER,
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
    licensedAiFeaturesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    duoFeaturesLocked: {
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
    environmentsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    featureFlagsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    infrastructureHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    releasesHelpPath: {
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
      visibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER,
      issuesAccessLevel: featureAccessLevel.EVERYONE,
      repositoryAccessLevel: featureAccessLevel.EVERYONE,
      forkingAccessLevel: featureAccessLevel.EVERYONE,
      mergeRequestsAccessLevel: featureAccessLevel.EVERYONE,
      packageRegistryAccessLevel: featureAccessLevel.EVERYONE,
      modelExperimentsAccessLevel: featureAccessLevel.EVERYONE,
      modelRegistryAccessLevel: featureAccessLevel.EVERYONE,
      buildsAccessLevel: featureAccessLevel.EVERYONE,
      wikiAccessLevel: featureAccessLevel.EVERYONE,
      snippetsAccessLevel: featureAccessLevel.EVERYONE,
      pagesAccessLevel: featureAccessLevel.EVERYONE,
      analyticsAccessLevel: featureAccessLevel.EVERYONE,
      requirementsAccessLevel: featureAccessLevel.EVERYONE,
      securityAndComplianceAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
      environmentsAccessLevel: featureAccessLevel.EVERYONE,
      featureFlagsAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
      infrastructureAccessLevel: featureAccessLevel.PROJECT_MEMBERS,
      releasesAccessLevel: featureAccessLevel.EVERYONE,
      monitorAccessLevel: featureAccessLevel.EVERYONE,
      containerRegistryAccessLevel: featureAccessLevel.EVERYONE,
      warnAboutPotentiallyUnwantedCharacters: true,
      lfsEnabled: true,
      requestAccessEnabled: true,
      enforceAuthChecksOnUploads: true,
      emailsEnabled: true,
      showDiffPreviewInEmail: true,
      cveIdRequestEnabled: true,
      duoFeaturesEnabled: false,
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
      if (this.visibilityLevel !== VISIBILITY_LEVEL_PRIVATE_INTEGER) {
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
        if (this.visibilityLevel === VISIBILITY_LEVEL_INTERNAL_INTEGER) {
          options.push(featureAccessLevelEveryone);
        }
      } else {
        if (this.visibilityLevel !== VISIBILITY_LEVEL_PRIVATE_INTEGER) {
          options.push(featureAccessLevelEveryone);
        }

        if (this.visibilityLevel !== VISIBILITY_LEVEL_PUBLIC_INTEGER) {
          options.push(FEATURE_ACCESS_LEVEL_ANONYMOUS);
        }
      }
      return options;
    },

    environmentsEnabled() {
      return this.environmentsAccessLevel > featureAccessLevel.NOT_ENABLED;
    },

    monitorEnabled() {
      return this.monitorAccessLevel > featureAccessLevel.NOT_ENABLED;
    },

    repositoryEnabled() {
      return this.repositoryAccessLevel > featureAccessLevel.NOT_ENABLED;
    },

    visibilityLevelDescription() {
      return visibilityLevelDescriptions[this.visibilityLevel];
    },

    showContainerRegistryPublicNote() {
      return (
        this.visibilityLevel === VISIBILITY_LEVEL_PUBLIC_INTEGER &&
        this.containerRegistryAccessLevel === featureAccessLevel.EVERYONE
      );
    },

    repositoryHelpText() {
      if (this.visibilityLevel === VISIBILITY_LEVEL_PRIVATE_INTEGER) {
        return s__('ProjectSettings|View and edit files in this project.');
      }

      return s__(
        'ProjectSettings|View and edit files in this project. When set to **Everyone With Access** non-project members have only read access.',
      );
    },
    cveIdRequestIsDisabled() {
      return this.visibilityLevel !== VISIBILITY_LEVEL_PUBLIC_INTEGER;
    },
    isVisibilityReduced() {
      return (
        this.showVisibilityConfirmModal &&
        this.visibilityLevel < this.currentSettings.visibilityLevel
      );
    },
    packageRegistryEnabled() {
      return this.packageRegistryAccessLevel > featureAccessLevel.NOT_ENABLED;
    },
    packageRegistryApiForEveryoneEnabled() {
      return this.packageRegistryAccessLevel === FEATURE_ACCESS_LEVEL_ANONYMOUS[0];
    },
    packageRegistryApiForEveryoneEnabledShown() {
      return (
        this.packageRegistryAllowAnyoneToPullOption &&
        this.visibilityLevel !== VISIBILITY_LEVEL_PUBLIC_INTEGER
      );
    },
    monitorOperationsFeatureAccessLevelOptions() {
      return this.featureAccessLevelOptions.filter(([value]) => value <= this.monitorAccessLevel);
    },
    findDiffPreviewValue: {
      get() {
        return this.emailsEnabled && this.showDiffPreviewInEmail;
      },
      set(newValue) {
        this.showDiffPreviewInEmail = newValue;
      },
    },
    showDuoSettings() {
      return this.licensedAiFeaturesAvailable && this.glFeatures.aiSettingsVueProject;
    },
  },

  watch: {
    visibilityLevel(value, oldValue) {
      if (value === VISIBILITY_LEVEL_PRIVATE_INTEGER) {
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
        if (
          this.packageRegistryAccessLevel === featureAccessLevel.EVERYONE ||
          (this.packageRegistryAccessLevel > featureAccessLevel.EVERYONE &&
            oldValue === VISIBILITY_LEVEL_PUBLIC_INTEGER)
        ) {
          this.packageRegistryAccessLevel = featureAccessLevel.PROJECT_MEMBERS;
        }
        this.modelExperimentsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.modelExperimentsAccessLevel,
        );
        this.modelRegistryAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.modelRegistryAccessLevel,
        );
        this.wikiAccessLevel = Math.min(featureAccessLevel.PROJECT_MEMBERS, this.wikiAccessLevel);
        this.snippetsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.snippetsAccessLevel,
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
        this.environmentsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.environmentsAccessLevel,
        );
        this.featureFlagsAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.featureFlagsAccessLevel,
        );
        this.infrastructureAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.infrastructureAccessLevel,
        );
        this.releasesAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.releasesAccessLevel,
        );
        this.monitorAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.monitorAccessLevel,
        );
        this.containerRegistryAccessLevel = Math.min(
          featureAccessLevel.PROJECT_MEMBERS,
          this.containerRegistryAccessLevel,
        );
        if (this.pagesAccessLevel === featureAccessLevel.EVERYONE) {
          // When from Internal->Private narrow access for only members
          this.pagesAccessLevel = featureAccessLevel.PROJECT_MEMBERS;
        }
      } else if (oldValue === VISIBILITY_LEVEL_PRIVATE_INTEGER) {
        // if changing away from private, make enabled features more permissive
        if (this.issuesAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.issuesAccessLevel = featureAccessLevel.EVERYONE;
        if (this.repositoryAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.repositoryAccessLevel = featureAccessLevel.EVERYONE;
        if (this.mergeRequestsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.mergeRequestsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.packageRegistryAccessLevel === featureAccessLevel.PROJECT_MEMBERS) {
          this.packageRegistryAccessLevel =
            PACKAGE_REGISTRY_ACCESS_LEVEL_DEFAULT_BY_PROJECT_VISIBILITY[value];
        }
        if (this.buildsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.buildsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.wikiAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.wikiAccessLevel = featureAccessLevel.EVERYONE;
        if (this.modelExperimentsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.modelExperimentsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.modelRegistryAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.modelRegistryAccessLevel = featureAccessLevel.EVERYONE;
        if (this.snippetsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.snippetsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.pagesAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.pagesAccessLevel = featureAccessLevel.EVERYONE;
        if (this.analyticsAccessLevel > featureAccessLevel.NOT_ENABLED)
          this.analyticsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.requirementsAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.requirementsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.environmentsAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.environmentsAccessLevel = featureAccessLevel.EVERYONE;
        if (this.monitorAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.monitorAccessLevel = featureAccessLevel.EVERYONE;
        if (this.containerRegistryAccessLevel === featureAccessLevel.PROJECT_MEMBERS)
          this.containerRegistryAccessLevel = featureAccessLevel.EVERYONE;
      } else if (
        value === VISIBILITY_LEVEL_PUBLIC_INTEGER &&
        this.packageRegistryAccessLevel === featureAccessLevel.EVERYONE
      ) {
        // eslint-disable-next-line prefer-destructuring
        this.packageRegistryAccessLevel = FEATURE_ACCESS_LEVEL_ANONYMOUS[0];
      } else if (
        value === VISIBILITY_LEVEL_INTERNAL_INTEGER &&
        this.packageRegistryAccessLevel === FEATURE_ACCESS_LEVEL_ANONYMOUS[0]
      ) {
        this.packageRegistryAccessLevel = featureAccessLevel.EVERYONE;
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
    visibilityAllowed(option) {
      return this.allowedVisibilityOptions.includes(option);
    },
    onPackageRegistryEnabledToggle(value) {
      this.packageRegistryAccessLevel = value
        ? this.packageRegistryAccessLevelDefault()
        : featureAccessLevel.NOT_ENABLED;
    },
    onPackageRegistryApiForEveryoneEnabledToggle(value) {
      this.packageRegistryAccessLevel = value
        ? FEATURE_ACCESS_LEVEL_ANONYMOUS[0]
        : this.packageRegistryAccessLevelDefault();
    },
    packageRegistryAccessLevelDefault() {
      return (
        PACKAGE_REGISTRY_ACCESS_LEVEL_DEFAULT_BY_PROJECT_VISIBILITY[this.visibilityLevel] ??
        featureAccessLevel.NOT_ENABLED
      );
    },
  },
};
</script>

<template>
  <div>
    <div
      class="project-visibility-setting gl-border-1 gl-border-solid gl-border-gray-100 gl-py-3 gl-px-5"
    >
      <project-setting-row
        ref="project-visibility-settings"
        :help-path="visibilityHelpPath"
        :label="s__('ProjectSettings|Project visibility')"
        :help-text="
          s__('ProjectSettings|Manage who can see the project in the public access directory.')
        "
      >
        <div class="project-feature-controls gl-flex gl-items-center gl-my-3 gl-mx-0">
          <div class="select-wrapper gl-flex-grow-1">
            <select
              v-model="visibilityLevel"
              :disabled="!canChangeVisibilityLevel"
              name="project[visibility_level]"
              class="form-control select-control"
              data-testid="project-visibility-dropdown"
            >
              <option
                :value="$options.VISIBILITY_LEVEL_PRIVATE_INTEGER"
                :disabled="!visibilityAllowed($options.VISIBILITY_LEVEL_PRIVATE_INTEGER)"
              >
                {{ s__('ProjectSettings|Private') }}
              </option>
              <option
                :value="$options.VISIBILITY_LEVEL_INTERNAL_INTEGER"
                :disabled="!visibilityAllowed($options.VISIBILITY_LEVEL_INTERNAL_INTEGER)"
              >
                {{ s__('ProjectSettings|Internal') }}
              </option>
              <option
                :value="$options.VISIBILITY_LEVEL_PUBLIC_INTEGER"
                :disabled="!visibilityAllowed($options.VISIBILITY_LEVEL_PUBLIC_INTEGER)"
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
          class="gl-block gl-text-gray-500 gl-mt-2"
          >{{
            s__(
              'ProjectSettings|Visibility options for this fork are limited by the current visibility of the source project.',
            )
          }}</span
        >
        <span class="gl-block gl-text-gray-500 gl-mt-2">
          <gl-sprintf :message="visibilityLevelDescription">
            <template #membersPageLink="{ content }">
              <gl-link class="gl-link" :href="membersPagePath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </span>
        <div class="gl-mt-4">
          <strong class="gl-block">{{ s__('ProjectSettings|Additional options') }}</strong>
          <label
            v-if="visibilityLevel !== $options.VISIBILITY_LEVEL_PRIVATE_INTEGER"
            class="gl-leading-28 gl-font-normal gl-mb-0"
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
            v-if="visibilityLevel !== $options.VISIBILITY_LEVEL_PUBLIC_INTEGER"
            class="gl-leading-28 gl-font-normal gl-block gl-mb-0"
          >
            <input
              :value="enforceAuthChecksOnUploads"
              type="hidden"
              name="project[project_setting_attributes][enforce_auth_checks_on_uploads]"
            />
            <input v-model="enforceAuthChecksOnUploads" type="checkbox" />
            {{ s__('ProjectSettings|Require authentication to view media files') }}
            <span class="gl-text-gray-500 gl-block gl-ml-5 -gl-mt-3">{{
              s__('ProjectSettings|Prevents direct linking to potentially sensitive media files')
            }}</span>
          </label>
        </div>
      </project-setting-row>
    </div>
    <div
      class="gl-border-1 gl-border-solid gl-border-t-none gl-border-gray-100 gl-mb-5 gl-py-3 gl-px-5 gl-bg-gray-10"
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
      <div class="project-feature-setting-group gl-pl-5 gl-md-pl-7">
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
                <span class="gl-display-block">
                  <gl-link :href="lfsObjectsRemovalHelpPath" target="_blank">
                    {{ content }}
                  </gl-link>
                </span>
              </template>
            </gl-sprintf>
          </p>
        </project-setting-row>
        <project-setting-row
          ref="pipeline-settings"
          :label="$options.i18n.ciCdLabel"
          :help-text="
            s__(
              'ProjectSettings|Build, test, and deploy your changes. Does not apply to project integrations.',
            )
          "
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
        :help-text="s__('ProjectSettings|Security and compliance for this project.')"
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
        v-if="packagesAvailable"
        :help-path="packagesHelpPath"
        :label="$options.i18n.packageRegistryLabel"
        :help-text="$options.i18n.packageRegistryHelpText"
        data-testid="package-registry-access-level"
      >
        <gl-toggle
          class="gl-my-2"
          :value="packageRegistryEnabled"
          :label="$options.i18n.packageRegistryLabel"
          label-position="hidden"
          name="package_registry_enabled"
          @change="onPackageRegistryEnabledToggle"
        />
        <div
          v-if="packageRegistryApiForEveryoneEnabledShown"
          class="project-feature-setting-group gl-pl-5 gl-md-pl-7 gl-my-3"
        >
          <project-setting-row
            :label="$options.i18n.packageRegistryForEveryoneLabel"
            :help-text="$options.i18n.packageRegistryForEveryoneHelpText"
          >
            <gl-toggle
              class="gl-my-2"
              :value="packageRegistryApiForEveryoneEnabled"
              :disabled="!packageRegistryEnabled"
              :label="$options.i18n.packageRegistryForEveryoneLabel"
              label-position="hidden"
              name="package_registry_api_for_everyone_enabled"
              @change="onPackageRegistryApiForEveryoneEnabledToggle"
            />
          </project-setting-row>
        </div>
        <input
          :value="packageRegistryAccessLevel"
          type="hidden"
          name="project[project_feature_attributes][package_registry_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="model-experiments-settings"
        :label="$options.i18n.modelExperimentsLabel"
        :help-text="$options.i18n.modelExperimentsHelpText"
        :help-path="$options.modelExperimentsHelpPath"
      >
        <project-feature-setting
          v-model="modelExperimentsAccessLevel"
          :label="$options.i18n.modelExperimentsLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][model_experiments_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="model-registry-settings"
        :label="$options.i18n.modelRegistryLabel"
        :help-text="$options.i18n.modelRegistryHelpText"
        :help-path="$options.modelRegistryHelpPath"
      >
        <project-feature-setting
          v-model="modelRegistryAccessLevel"
          :label="$options.i18n.modelRegistryLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][model_registry_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        v-if="pagesAvailable && pagesAccessControlEnabled"
        ref="pages-settings"
        :help-path="pagesHelpPath"
        :label="$options.i18n.pagesLabel"
        :help-text="
          s__(
            'ProjectSettings|With GitLab Pages you can host your static websites on GitLab. GitLab Pages uses a caching mechanism for efficiency. Your changes may not take effect until that cache is invalidated, which usually takes less than a minute.',
          )
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
        ref="monitor-settings"
        :label="$options.i18n.monitorLabel"
        :help-text="
          s__('ProjectSettings|Monitor the health of your project and respond to incidents.')
        "
      >
        <project-feature-setting
          v-model="monitorAccessLevel"
          :label="$options.i18n.monitorLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][monitor_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="environments-settings"
        :label="$options.i18n.environmentsLabel"
        :help-text="$options.i18n.environmentsHelpText"
        :help-path="environmentsHelpPath"
      >
        <project-feature-setting
          v-model="environmentsAccessLevel"
          :label="$options.i18n.environmentsLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][environments_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="feature-flags-settings"
        :label="$options.i18n.featureFlagsLabel"
        :help-text="$options.i18n.featureFlagsHelpText"
        :help-path="featureFlagsHelpPath"
      >
        <project-feature-setting
          v-model="featureFlagsAccessLevel"
          :label="$options.i18n.featureFlagsLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][feature_flags_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="infrastructure-settings"
        :label="$options.i18n.infrastructureLabel"
        :help-text="$options.i18n.infrastructureHelpText"
        :help-path="infrastructureHelpPath"
      >
        <project-feature-setting
          v-model="infrastructureAccessLevel"
          :label="$options.i18n.infrastructureLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][infrastructure_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        ref="releases-settings"
        :label="$options.i18n.releasesLabel"
        :help-text="$options.i18n.releasesHelpText"
        :help-path="releasesHelpPath"
      >
        <project-feature-setting
          v-model="releasesAccessLevel"
          :label="$options.i18n.releasesLabel"
          :options="featureAccessLevelOptions"
          name="project[project_feature_attributes][releases_access_level]"
        />
      </project-setting-row>
      <project-setting-row
        v-if="showDuoSettings"
        data-testid="duo-settings"
        :label="$options.i18n.duoLabel"
        :help-text="$options.i18n.duoHelpText"
        :help-path="$options.duoHelpPath"
        :locked="duoFeaturesLocked"
      >
        <gl-toggle
          v-model="duoFeaturesEnabled"
          class="gl-mt-2 gl-mb-4"
          :disabled="duoFeaturesLocked"
          :label="$options.i18n.duoLabel"
          label-position="hidden"
          name="project[project_setting_attributes][duo_features_enabled]"
          data-testid="duo_features_enabled_toggle"
        />
      </project-setting-row>
    </div>

    <project-setting-row v-if="canDisableEmails" ref="email-settings" class="mb-3">
      <label class="js-emails-enabled">
        <h5>{{ $options.i18n.emailsLabel }}</h5>
        <input
          :value="emailsEnabled"
          type="hidden"
          name="project[project_setting_attributes][emails_enabled]"
        />
        <gl-form-checkbox v-model="emailsEnabled">
          {{ s__('ProjectSettings|Enable email notifications') }}
          <template #help>{{
            s__('ProjectSettings|Enable sending email notifications for this project')
          }}</template>
        </gl-form-checkbox>
      </label>
      <project-setting-row
        v-if="canSetDiffPreviewInEmail"
        ref="enable-diff-preview-settings"
        class="gl-px-7"
      >
        <input
          :value="findDiffPreviewValue"
          type="hidden"
          name="project[project_setting_attributes][show_diff_preview_in_email]"
        />
        <gl-form-checkbox v-model="findDiffPreviewValue" :disabled="!emailsEnabled">
          {{ $options.i18n.showDiffPreviewLabel }}
          <template #help>{{ $options.i18n.showDiffPreviewHelpText }}</template>
        </gl-form-checkbox>
      </project-setting-row>
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
        {{ s__('ProjectSettings|Show default emoji reactions') }}
        <template #help>{{
          s__(
            'ProjectSettings|Always show thumbs-up and thumbs-down emoji buttons on issues, merge requests, and snippets.',
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
    <ci-catalog-settings
      v-if="canAddCatalogResource"
      class="gl-mb-5"
      :full-path="confirmationPhrase"
    />
    <other-project-settings />
    <confirm-danger
      v-if="isVisibilityReduced"
      button-variant="confirm"
      :disabled="false"
      :phrase="confirmationPhrase"
      :button-text="$options.i18n.confirmButtonText"
      data-testid="project-features-save-button"
      @confirm="$emit('confirm')"
    />
    <gl-button v-else type="submit" variant="confirm" data-testid="project-features-save-button">
      {{ $options.i18n.confirmButtonText }}
    </gl-button>
  </div>
</template>
