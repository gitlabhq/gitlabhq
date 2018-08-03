<script>
import Timeago from 'timeago.js';
import _ from 'underscore';
import tooltip from '~/vue_shared/directives/tooltip';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { humanize } from '~/lib/utils/text_utility';
import ActionsComponent from './environment_actions.vue';
import ExternalUrlComponent from './environment_external_url.vue';
import StopComponent from './environment_stop.vue';
import RollbackComponent from './environment_rollback.vue';
import TerminalButtonComponent from './environment_terminal_button.vue';
import MonitoringButtonComponent from './environment_monitoring.vue';
import CommitComponent from '../../vue_shared/components/commit.vue';
import eventHub from '../event_hub';

/**
 * Envrionment Item Component
 *
 * Renders a table row for each environment.
 */
const timeagoInstance = new Timeago();

export default {
  components: {
    UserAvatarLink,
    CommitComponent,
    ActionsComponent,
    ExternalUrlComponent,
    StopComponent,
    RollbackComponent,
    TerminalButtonComponent,
    MonitoringButtonComponent,
  },

  directives: {
    tooltip,
  },

  props: {
    model: {
      type: Object,
      required: true,
      default: () => ({}),
    },

    canCreateDeployment: {
      type: Boolean,
      required: false,
      default: false,
    },

    canReadEnvironment: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    /**
     * Verifies if `last_deployment` key exists in the current Envrionment.
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
     * Verifies is the given environment has manual actions.
     * Used to verify if we should render them or nor.
     *
     * @returns {Boolean|Undefined}
     */
    hasManualActions() {
      return (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.manual_actions &&
        this.model.last_deployment.manual_actions.length > 0
      );
    },

    /**
     * Checkes whether the user is allowed to deploy to this environment.
     * (`can_deploy` currently only set in EE)
     *
     * @returns {Boolean}
     */
    isDeployableByUser() {
      return this.model && 'can_deploy' in this.model
        ? this.model.can_deploy
        : this.canCreateDeployment;
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
        this.model.last_deployment.deployable
      );
    },

    /**
     * Verifies if the date to be shown is present.
     *
     * @returns {Boolean|Undefined}
     */
    canShowDate() {
      return (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable &&
        this.model.last_deployment.deployable !== undefined
      );
    },

    /**
     * Human readable date.
     *
     * @returns {String}
     */
    createdDate() {
      if (
        this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable &&
        this.model.last_deployment.deployable.created_at
      ) {
        return timeagoInstance.format(this.model.last_deployment.deployable.created_at);
      }
      return '';
    },

    /**
     * Returns the manual actions with the name parsed.
     *
     * @returns {Array.<Object>|Undefined}
     */
    manualActions() {
      if (this.hasManualActions) {
        return this.model.last_deployment.manual_actions.map(action => {
          const parsedAction = {
            name: humanize(action.name),
            play_path: action.play_path,
            playable: action.playable,
          };
          return parsedAction;
        });
      }
      return [];
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
        return `${this.model.last_deployment.user.username}'s avatar'`;
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
        this.hasManualActions ||
        this.externalURL ||
        this.monitoringUrl ||
        this.canStopEnvironment ||
        this.canRetry
      );
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
    role="row">
    <div
      class="table-section section-wrap section-15"
      role="gridcell"
    >
      <div
        v-if="!model.isFolder"
        class="table-mobile-header"
        role="rowheader"
      >
        {{ s__("Environments|Environment") }}
      </div>
      <span
        v-if="!model.isFolder"
        class="environment-name table-mobile-content">
        <a
          v-tooltip
          :href="environmentPath"
          :title="model.name"
        >
          {{ model.name }}
        </a>
      </span>
      <span
        v-else
        class="folder-name"
        role="button"
        @click="onClickFolder">

        <span class="folder-icon">
          <i
            v-show="model.isOpen"
            class="fa fa-caret-down"
            aria-hidden="true"
          >
          </i>
          <i
            v-show="!model.isOpen"
            class="fa fa-caret-right"
            aria-hidden="true"
          >
          </i>
        </span>

        <span class="folder-icon">
          <i
            class="fa fa-folder"
            aria-hidden="true">
          </i>
        </span>

        <span>
          {{ model.folderName }}
        </span>

        <span class="badge badge-pill">
          {{ model.size }}
        </span>
      </span>
    </div>

    <div
      class="table-section section-10 deployment-column d-none d-sm-none d-md-block"
      role="gridcell"
    >
      <span v-if="shouldRenderDeploymentID">
        {{ deploymentInternalId }}
      </span>

      <span v-if="!model.isFolder && deploymentHasUser">
        by
        <user-avatar-link
          :link-href="deploymentUser.web_url"
          :img-src="deploymentUser.avatar_url"
          :img-alt="userImageAltDescription"
          :tooltip-text="deploymentUser.username"
          class="js-deploy-user-container"
        />
      </span>
    </div>

    <div
      class="table-section section-15 d-none d-sm-none d-md-block"
      role="gridcell"
    >
      <a
        v-if="shouldRenderBuildName"
        :href="buildPath"
        class="build-link flex-truncate-parent"
      >
        <span class="flex-truncate-child">{{ buildName }}</span>
      </a>
    </div>

    <div
      v-if="!model.isFolder"
      class="table-section section-20"
      role="gridcell"
    >
      <div
        role="rowheader"
        class="table-mobile-header"
      >
        {{ s__("Environments|Commit") }}
      </div>
      <div
        v-if="hasLastDeploymentKey"
        class="js-commit-component table-mobile-content">
        <commit-component
          :tag="commitTag"
          :commit-ref="commitRef"
          :commit-url="commitUrl"
          :short-sha="commitShortSha"
          :title="commitTitle"
          :author="commitAuthor"/>
      </div>
      <div
        v-if="!hasLastDeploymentKey"
        class="commit-title table-mobile-content">
        {{ s__("Environments|No deployments yet") }}
      </div>
    </div>

    <div
      v-if="!model.isFolder"
      class="table-section section-10"
      role="gridcell"
    >
      <div
        role="rowheader"
        class="table-mobile-header">
        {{ s__("Environments|Updated") }}
      </div>
      <span
        v-if="canShowDate"
        class="environment-created-date-timeago table-mobile-content">
        {{ createdDate }}
      </span>
    </div>

    <div
      v-if="!model.isFolder && displayEnvironmentActions"
      class="table-section section-30 table-button-footer"
      role="gridcell">

      <div
        class="btn-group table-action-buttons"
        role="group">

        <external-url-component
          v-if="externalURL && canReadEnvironment"
          :external-url="externalURL"
        />

        <monitoring-button-component
          v-if="monitoringUrl && canReadEnvironment"
          :monitoring-url="monitoringUrl"
        />

        <actions-component
          v-if="hasManualActions && isDeployableByUser"
          :actions="manualActions"
        />

        <terminal-button-component
          v-if="model && model.terminal_path"
          :terminal-path="model.terminal_path"
        />

        <rollback-component
          v-if="canRetry && isDeployableByUser"
          :is-last-deployment="isLastDeployment"
          :retry-url="retryUrl"
        />

        <stop-component
          v-if="canStopEnvironment"
          :environment="model"
        />
      </div>
    </div>
  </div>
</template>
