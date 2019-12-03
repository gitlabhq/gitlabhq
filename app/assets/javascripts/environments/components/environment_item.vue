<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import { __, sprintf } from '~/locale';
import { format } from 'timeago.js';
import _ from 'underscore';
import { GlTooltipDirective } from '@gitlab/ui';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import environmentItemMixin from 'ee_else_ce/environments/mixins/environment_item_mixin';
import ActionsComponent from './environment_actions.vue';
import ExternalUrlComponent from './environment_external_url.vue';
import StopComponent from './environment_stop.vue';
import RollbackComponent from './environment_rollback.vue';
import TerminalButtonComponent from './environment_terminal_button.vue';
import MonitoringButtonComponent from './environment_monitoring.vue';
import CommitComponent from '../../vue_shared/components/commit.vue';
import eventHub from '../event_hub';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

/**
 * Environment Item Component
 *
 * Renders a table row for each environment.
 */

export default {
  components: {
    CommitComponent,
    Icon,
    ActionsComponent,
    ExternalUrlComponent,
    StopComponent,
    RollbackComponent,
    TerminalButtonComponent,
    MonitoringButtonComponent,
    TooltipOnTruncate,
    UserAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [environmentItemMixin],

  props: {
    canReadEnvironment: {
      type: Boolean,
      required: false,
      default: false,
    },

    model: {
      type: Object,
      required: true,
      default: () => ({}),
    },

    tableData: {
      type: Object,
      required: true,
    },
  },

  computed: {
    /**
     * Verifies if `last_deployment` key exists in the current Environment.
     * This key is required to render most of the html - this method works has
     * an helper.
     *
     * @returns {Boolean}
     */
    hasLastDeploymentKey() {
      if (this.model && this.model.last_deployment && !_.isEmpty(this.model.last_deployment)) {
        return true;
      }
      return false;
    },

    /**
     * Checkes whether the environment is protected.
     * (`is_protected` currently only set in EE)
     *
     * @returns {Boolean}
     */
    isProtected() {
      return this.model && this.model.is_protected;
    },

    /**
     * Returns whether the environment can be stopped.
     *
     * @returns {Boolean}
     */
    canStopEnvironment() {
      return this.model && this.model.can_stop;
    },

    /**
     * Verifies if the `deployable` key is present in `last_deployment` key.
     * Used to verify whether we should or not render the rollback partial.
     *
     * @returns {Boolean|Undefined}
     */
    canRetry() {
      return (
        this.model &&
        this.hasLastDeploymentKey &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable &&
        this.model.last_deployment.deployable.retry_path
      );
    },

    /**
     * Verifies if the date to be shown is present.
     *
     * @returns {Boolean|Undefined}
     */
    canShowDate() {
      return this.model && this.model.last_deployment && this.model.last_deployment.deployed_at;
    },

    /**
     * Human readable date.
     *
     * @returns {String}
     */
    deployedDate() {
      if (this.canShowDate) {
        return format(this.model.last_deployment.deployed_at);
      }
      return '';
    },

    actions() {
      if (!this.model || !this.model.last_deployment) {
        return [];
      }

      const { manualActions, scheduledActions } = convertObjectPropsToCamelCase(
        this.model.last_deployment,
        { deep: true },
      );
      const combinedActions = (manualActions || []).concat(scheduledActions || []);
      return combinedActions.map(action => ({
        ...action,
        name: action.name,
      }));
    },

    /**
     * Builds the string used in the user image alt attribute.
     *
     * @returns {String}
     */
    userImageAltDescription() {
      if (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.user &&
        this.model.last_deployment.user.username
      ) {
        return sprintf(__("%{username}'s avatar"), {
          username: this.model.last_deployment.user.username,
        });
      }
      return '';
    },

    /**
     * If provided, returns the commit tag.
     *
     * @returns {String|Undefined}
     */
    commitTag() {
      if (this.model && this.model.last_deployment && this.model.last_deployment.tag) {
        return this.model.last_deployment.tag;
      }
      return undefined;
    },

    /**
     * If provided, returns the commit ref.
     *
     * @returns {Object|Undefined}
     */
    commitRef() {
      if (this.model && this.model.last_deployment && this.model.last_deployment.ref) {
        return this.model.last_deployment.ref;
      }
      return undefined;
    },

    /**
     * If provided, returns the commit url.
     *
     * @returns {String|Undefined}
     */
    commitUrl() {
      if (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.commit &&
        this.model.last_deployment.commit.commit_path
      ) {
        return this.model.last_deployment.commit.commit_path;
      }
      return undefined;
    },

    /**
     * If provided, returns the commit short sha.
     *
     * @returns {String|Undefined}
     */
    commitShortSha() {
      if (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.commit &&
        this.model.last_deployment.commit.short_id
      ) {
        return this.model.last_deployment.commit.short_id;
      }
      return undefined;
    },

    /**
     * If provided, returns the commit title.
     *
     * @returns {String|Undefined}
     */
    commitTitle() {
      if (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.commit &&
        this.model.last_deployment.commit.title
      ) {
        return this.model.last_deployment.commit.title;
      }
      return undefined;
    },

    /**
     * If provided, returns the commit tag.
     *
     * @returns {Object|Undefined}
     */
    commitAuthor() {
      if (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.commit &&
        this.model.last_deployment.commit.author
      ) {
        return this.model.last_deployment.commit.author;
      }

      return undefined;
    },

    /**
     * Verifies if the `retry_path` key is present and returns its value.
     *
     * @returns {String|Undefined}
     */
    retryUrl() {
      if (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable &&
        this.model.last_deployment.deployable.retry_path
      ) {
        return this.model.last_deployment.deployable.retry_path;
      }
      return undefined;
    },

    /**
     * Verifies if the `last?` key is present and returns its value.
     *
     * @returns {Boolean|Undefined}
     */
    isLastDeployment() {
      // name: 'last?' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
      // Vue i18n ESLint rules issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/63560
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return this.model && this.model.last_deployment && this.model.last_deployment['last?'];
    },

    /**
     * Builds the name of the builds needed to display both the name and the id.
     *
     * @returns {String}
     */
    buildName() {
      if (this.model && this.model.last_deployment && this.model.last_deployment.deployable) {
        const { deployable } = this.model.last_deployment;
        return `${deployable.name} #${deployable.id}`;
      }
      return '';
    },

    /**
     * Builds the needed string to show the internal id.
     *
     * @returns {String}
     */
    deploymentInternalId() {
      if (this.model && this.model.last_deployment && this.model.last_deployment.iid) {
        return `#${this.model.last_deployment.iid}`;
      }
      return '';
    },

    /**
     * Verifies if the user object is present under last_deployment object.
     *
     * @returns {Boolean}
     */
    deploymentHasUser() {
      return (
        this.model &&
        !_.isEmpty(this.model.last_deployment) &&
        !_.isEmpty(this.model.last_deployment.user)
      );
    },

    /**
     * Returns the user object nested with the last_deployment object.
     * Used to render the template.
     *
     * @returns {Object}
     */
    deploymentUser() {
      if (
        this.model &&
        !_.isEmpty(this.model.last_deployment) &&
        !_.isEmpty(this.model.last_deployment.user)
      ) {
        return this.model.last_deployment.user;
      }
      return {};
    },

    /**
     * Verifies if the build name column should be rendered by verifing
     * if all the information needed is present
     * and if the environment is not a folder.
     *
     * @returns {Boolean}
     */
    shouldRenderBuildName() {
      return (
        !this.model.isFolder &&
        !_.isEmpty(this.model.last_deployment) &&
        !_.isEmpty(this.model.last_deployment.deployable)
      );
    },

    /**
     * Verifies the presence of all the keys needed to render the buil_path.
     *
     * @return {String}
     */
    buildPath() {
      if (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable &&
        this.model.last_deployment.deployable.build_path
      ) {
        return this.model.last_deployment.deployable.build_path;
      }

      return '';
    },

    /**
     * Verifies the presence of all the keys needed to render the external_url.
     *
     * @return {String}
     */
    externalURL() {
      if (this.model && this.model.external_url) {
        return this.model.external_url;
      }

      return '';
    },

    /**
     * Verifies if deplyment internal ID should be rendered by verifing
     * if all the information needed is present
     * and if the environment is not a folder.
     *
     * @returns {Boolean}
     */
    shouldRenderDeploymentID() {
      return (
        !this.model.isFolder &&
        !_.isEmpty(this.model.last_deployment) &&
        this.model.last_deployment.iid !== undefined
      );
    },

    environmentPath() {
      if (this.model && this.model.environment_path) {
        return this.model.environment_path;
      }

      return '';
    },

    monitoringUrl() {
      if (this.model && this.model.metrics_path) {
        return this.model.metrics_path;
      }

      return '';
    },

    displayEnvironmentActions() {
      return (
        this.actions.length > 0 ||
        this.externalURL ||
        this.monitoringUrl ||
        this.canStopEnvironment ||
        this.canRetry
      );
    },

    folderIconName() {
      return this.model.isOpen ? 'chevron-down' : 'chevron-right';
    },
  },

  methods: {
    onClickFolder() {
      eventHub.$emit('toggleFolder', this.model);
    },
  },
};
</script>
<template>
  <div
    :class="{
      'js-child-row environment-child-row': model.isChildren,
      'folder-row': model.isFolder,
    }"
    class="gl-responsive-table-row"
    role="row"
  >
    <div
      class="table-section section-wrap text-truncate"
      :class="tableData.name.spacing"
      role="gridcell"
    >
      <div v-if="!model.isFolder" class="table-mobile-header" role="rowheader">
        {{ tableData.name.title }}
      </div>

      <span v-if="shouldRenderDeployBoard" class="deploy-board-icon" @click="toggleDeployBoard">
        <icon :name="deployIconName" />
      </span>

      <span
        v-if="!model.isFolder"
        v-gl-tooltip
        :title="model.name"
        class="environment-name table-mobile-content"
      >
        <a class="qa-environment-link" :href="environmentPath">
          <span v-if="model.size === 1">{{ model.name }}</span>
          <span v-else>{{ model.name_without_type }}</span>
        </a>
        <span v-if="isProtected" class="badge badge-success">
          {{ s__('Environments|protected') }}
        </span>
      </span>
      <span
        v-else
        v-gl-tooltip
        :title="model.folderName"
        class="folder-name"
        role="button"
        @click="onClickFolder"
      >
        <icon :name="folderIconName" class="folder-icon" />

        <icon name="folder" class="folder-icon" />

        <span> {{ model.folderName }} </span>

        <span class="badge badge-pill"> {{ model.size }} </span>
      </span>
    </div>

    <div
      class="table-section deployment-column d-none d-sm-none d-md-block"
      :class="tableData.deploy.spacing"
      role="gridcell"
    >
      <span v-if="shouldRenderDeploymentID" class="text-break-word">
        {{ deploymentInternalId }}
      </span>

      <span v-if="!model.isFolder && deploymentHasUser" class="text-break-word">
        by
        <user-avatar-link
          :link-href="deploymentUser.web_url"
          :img-src="deploymentUser.avatar_url"
          :img-alt="userImageAltDescription"
          :tooltip-text="deploymentUser.username"
          class="js-deploy-user-container float-none"
        />
      </span>
    </div>

    <div
      class="table-section d-none d-sm-none d-md-block"
      :class="tableData.build.spacing"
      role="gridcell"
    >
      <a v-if="shouldRenderBuildName" :href="buildPath" class="build-link cgray">
        <tooltip-on-truncate
          :title="buildName"
          truncate-target="child"
          class="flex-truncate-parent"
        >
          <span class="flex-truncate-child">
            {{ buildName }}
          </span>
        </tooltip-on-truncate>
      </a>
    </div>

    <div
      v-if="!model.isFolder"
      class="table-section"
      :class="tableData.commit.spacing"
      role="gridcell"
    >
      <div role="rowheader" class="table-mobile-header">{{ tableData.commit.title }}</div>

      <div v-if="hasLastDeploymentKey" class="js-commit-component table-mobile-content">
        <commit-component
          :tag="commitTag"
          :commit-ref="commitRef"
          :commit-url="commitUrl"
          :short-sha="commitShortSha"
          :title="commitTitle"
          :author="commitAuthor"
        />
      </div>
      <div v-if="!hasLastDeploymentKey" class="commit-title table-mobile-content">
        {{ s__('Environments|No deployments yet') }}
      </div>
    </div>

    <div
      v-if="!model.isFolder"
      class="table-section"
      :class="tableData.date.spacing"
      role="gridcell"
    >
      <div role="rowheader" class="table-mobile-header">{{ tableData.date.title }}</div>

      <span v-if="canShowDate" class="environment-created-date-timeago table-mobile-content">
        {{ deployedDate }}
      </span>
    </div>

    <div
      v-if="!model.isFolder && displayEnvironmentActions"
      class="table-section table-button-footer"
      :class="tableData.actions.spacing"
      role="gridcell"
    >
      <div class="btn-group table-action-buttons" role="group">
        <external-url-component
          v-if="externalURL && canReadEnvironment"
          :external-url="externalURL"
        />

        <monitoring-button-component
          v-if="monitoringUrl && canReadEnvironment"
          :monitoring-url="monitoringUrl"
        />

        <actions-component v-if="actions.length > 0" :actions="actions" />

        <terminal-button-component
          v-if="model && model.terminal_path"
          :terminal-path="model.terminal_path"
        />

        <rollback-component
          v-if="canRetry"
          :environment="model"
          :is-last-deployment="isLastDeployment"
          :retry-url="retryUrl"
        />

        <stop-component v-if="canStopEnvironment" :environment="model" />
      </div>
    </div>
  </div>
</template>
