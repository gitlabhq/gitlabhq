<script>
  import Timeago from 'timeago.js';
  import _ from 'underscore';
  import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
  import { humanize } from '../../lib/utils/text_utility';
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
      userAvatarLink,
      'commit-component': CommitComponent,
      'actions-component': ActionsComponent,
      'external-url-component': ExternalUrlComponent,
      'stop-component': StopComponent,
      'rollback-component': RollbackComponent,
      'terminal-button-component': TerminalButtonComponent,
      'monitoring-button-component': MonitoringButtonComponent,
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
<<<<<<< HEAD
       * Verifies if `last_deployment` key exists in the current Environment.
       * This key is required to render most of the html - this method works has
       * an helper.
       *
       * @returns {Boolean}
       */
=======
      * Verifies if `last_deployment` key exists in the current Envrionment.
      * This key is required to render most of the html - this method works has
      * an helper.
      *
      * @returns {Boolean}
      */
>>>>>>> upstream/master
      hasLastDeploymentKey() {
        if (this.model &&
          this.model.last_deployment &&
          !_.isEmpty(this.model.last_deployment)) {
          return true;
        }
        return false;
      },

      /**
<<<<<<< HEAD
       * Verifies is the given environment has manual actions.
       * Used to verify if we should render them or nor.
       *
       * @returns {Boolean|Undefined}
       */
=======
      * Verifies is the given environment has manual actions.
      * Used to verify if we should render them or nor.
      *
      * @returns {Boolean|Undefined}
      */
>>>>>>> upstream/master
      hasManualActions() {
        return this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.manual_actions &&
          this.model.last_deployment.manual_actions.length > 0;
      },

      /**
<<<<<<< HEAD
       * Returns the value of the `stop_action?` key provided in the response.
       *
       * @returns {Boolean}
       */
=======
      * Returns the value of the `stop_action?` key provided in the response.
      *
      * @returns {Boolean}
      */
>>>>>>> upstream/master
      hasStopAction() {
        return this.model && this.model['stop_action?'];
      },

      /**
<<<<<<< HEAD
       * Verifies if the `deployable` key is present in `last_deployment` key.
       * Used to verify whether we should or not render the rollback partial.
       *
       * @returns {Boolean|Undefined}
       */
=======
      * Verifies if the `deployable` key is present in `last_deployment` key.
      * Used to verify whether we should or not render the rollback partial.
      *
      * @returns {Boolean|Undefined}
      */
>>>>>>> upstream/master
      canRetry() {
        return this.model &&
          this.hasLastDeploymentKey &&
          this.model.last_deployment &&
          this.model.last_deployment.deployable;
      },

      /**
<<<<<<< HEAD
       * Verifies if the date to be shown is present.
       *
       * @returns {Boolean|Undefined}
       */
=======
      * Verifies if the date to be shown is present.
      *
      * @returns {Boolean|Undefined}
      */
>>>>>>> upstream/master
      canShowDate() {
        return this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.deployable &&
          this.model.last_deployment.deployable !== undefined;
      },

      /**
<<<<<<< HEAD
       * Human readable date.
       *
       * @returns {String}
       */
=======
      * Human readable date.
      *
      * @returns {String}
      */
>>>>>>> upstream/master
      createdDate() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.deployable &&
          this.model.last_deployment.deployable.created_at) {
          return timeagoInstance.format(this.model.last_deployment.deployable.created_at);
        }
        return '';
      },

      /**
<<<<<<< HEAD
       * Returns the manual actions with the name parsed.
       *
       * @returns {Array.<Object>|Undefined}
       */
=======
      * Returns the manual actions with the name parsed.
      *
      * @returns {Array.<Object>|Undefined}
      */
>>>>>>> upstream/master
      manualActions() {
        if (this.hasManualActions) {
          return this.model.last_deployment.manual_actions.map((action) => {
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
<<<<<<< HEAD
       * Builds the string used in the user image alt attribute.
       *
       * @returns {String}
       */
=======
      * Builds the string used in the user image alt attribute.
      *
      * @returns {String}
      */
>>>>>>> upstream/master
      userImageAltDescription() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.user &&
          this.model.last_deployment.user.username) {
          return `${this.model.last_deployment.user.username}'s avatar'`;
        }
        return '';
      },

      /**
<<<<<<< HEAD
       * If provided, returns the commit tag.
       *
       * @returns {String|Undefined}
       */
=======
      * If provided, returns the commit tag.
      *
      * @returns {String|Undefined}
      */
>>>>>>> upstream/master
      commitTag() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.tag) {
          return this.model.last_deployment.tag;
        }
        return undefined;
      },

      /**
<<<<<<< HEAD
       * If provided, returns the commit ref.
       *
       * @returns {Object|Undefined}
       */
=======
      * If provided, returns the commit ref.
      *
      * @returns {Object|Undefined}
      */
>>>>>>> upstream/master
      commitRef() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.ref) {
          return this.model.last_deployment.ref;
        }
        return undefined;
      },

      /**
<<<<<<< HEAD
       * If provided, returns the commit url.
       *
       * @returns {String|Undefined}
       */
=======
      * If provided, returns the commit url.
      *
      * @returns {String|Undefined}
      */
>>>>>>> upstream/master
      commitUrl() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.commit_path) {
          return this.model.last_deployment.commit.commit_path;
        }
        return undefined;
      },

      /**
<<<<<<< HEAD
       * If provided, returns the commit short sha.
       *
       * @returns {String|Undefined}
       */
=======
      * If provided, returns the commit short sha.
      *
      * @returns {String|Undefined}
      */
>>>>>>> upstream/master
      commitShortSha() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.short_id) {
          return this.model.last_deployment.commit.short_id;
        }
        return undefined;
      },

      /**
<<<<<<< HEAD
       * If provided, returns the commit title.
       *
       * @returns {String|Undefined}
       */
=======
      * If provided, returns the commit title.
      *
      * @returns {String|Undefined}
      */
>>>>>>> upstream/master
      commitTitle() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.title) {
          return this.model.last_deployment.commit.title;
        }
        return undefined;
      },

      /**
<<<<<<< HEAD
       * If provided, returns the commit tag.
       *
       * @returns {Object|Undefined}
       */
=======
      * If provided, returns the commit tag.
      *
      * @returns {Object|Undefined}
      */
>>>>>>> upstream/master
      commitAuthor() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.author) {
          return this.model.last_deployment.commit.author;
        }

        return undefined;
      },

      /**
<<<<<<< HEAD
       * Verifies if the `retry_path` key is present and returns its value.
       *
       * @returns {String|Undefined}
       */
=======
      * Verifies if the `retry_path` key is present and returns its value.
      *
      * @returns {String|Undefined}
      */
>>>>>>> upstream/master
      retryUrl() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.deployable &&
          this.model.last_deployment.deployable.retry_path) {
          return this.model.last_deployment.deployable.retry_path;
        }
        return undefined;
      },

      /**
<<<<<<< HEAD
       * Verifies if the `last?` key is present and returns its value.
       *
       * @returns {Boolean|Undefined}
       */
=======
      * Verifies if the `last?` key is present and returns its value.
      *
      * @returns {Boolean|Undefined}
      */
>>>>>>> upstream/master
      isLastDeployment() {
        return this.model && this.model.last_deployment &&
          this.model.last_deployment['last?'];
      },

      /**
<<<<<<< HEAD
       * Builds the name of the builds needed to display both the name and the id.
       *
       * @returns {String}
       */
=======
      * Builds the name of the builds needed to display both the name and the id.
      *
      * @returns {String}
      */
>>>>>>> upstream/master
      buildName() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.deployable) {
<<<<<<< HEAD
          return `${this.model.last_deployment.deployable.name} #${this.model.last_deployment.deployable.id}`;
=======
          const deployable = this.model.last_deployment.deployable;
          return `${deployable.name} #${deployable.id}`;
>>>>>>> upstream/master
        }
        return '';
      },

      /**
<<<<<<< HEAD
       * Builds the needed string to show the internal id.
       *
       * @returns {String}
       */
=======
      * Builds the needed string to show the internal id.
      *
      * @returns {String}
      */
>>>>>>> upstream/master
      deploymentInternalId() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.iid) {
          return `#${this.model.last_deployment.iid}`;
        }
        return '';
      },

      /**
<<<<<<< HEAD
       * Verifies if the user object is present under last_deployment object.
       *
       * @returns {Boolean}
       */
=======
      * Verifies if the user object is present under last_deployment object.
      *
      * @returns {Boolean}
      */
>>>>>>> upstream/master
      deploymentHasUser() {
        return this.model &&
          !_.isEmpty(this.model.last_deployment) &&
          !_.isEmpty(this.model.last_deployment.user);
      },

      /**
<<<<<<< HEAD
       * Returns the user object nested with the last_deployment object.
       * Used to render the template.
       *
       * @returns {Object}
       */
=======
      * Returns the user object nested with the last_deployment object.
      * Used to render the template.
      *
      * @returns {Object}
      */
>>>>>>> upstream/master
      deploymentUser() {
        if (this.model &&
          !_.isEmpty(this.model.last_deployment) &&
          !_.isEmpty(this.model.last_deployment.user)) {
          return this.model.last_deployment.user;
        }
        return {};
      },

      /**
<<<<<<< HEAD
       * Verifies if the build name column should be rendered by verifing
       * if all the information needed is present
       * and if the environment is not a folder.
       *
       * @returns {Boolean}
       */
=======
      * Verifies if the build name column should be rendered by verifing
      * if all the information needed is present
      * and if the environment is not a folder.
      *
      * @returns {Boolean}
      */
>>>>>>> upstream/master
      shouldRenderBuildName() {
        return !this.model.isFolder &&
          !_.isEmpty(this.model.last_deployment) &&
          !_.isEmpty(this.model.last_deployment.deployable);
      },

      /**
<<<<<<< HEAD
       * Verifies the presence of all the keys needed to render the buil_path.
       *
       * @return {String}
       */
=======
      * Verifies the presence of all the keys needed to render the buil_path.
      *
      * @return {String}
      */
>>>>>>> upstream/master
      buildPath() {
        if (this.model &&
          this.model.last_deployment &&
          this.model.last_deployment.deployable &&
          this.model.last_deployment.deployable.build_path) {
          return this.model.last_deployment.deployable.build_path;
        }

        return '';
      },

      /**
<<<<<<< HEAD
       * Verifies the presence of all the keys needed to render the external_url.
       *
       * @return {String}
       */
=======
      * Verifies the presence of all the keys needed to render the external_url.
      *
      * @return {String}
      */
>>>>>>> upstream/master
      externalURL() {
        if (this.model && this.model.external_url) {
          return this.model.external_url;
        }

        return '';
      },

      /**
<<<<<<< HEAD
       * Verifies if deplyment internal ID should be rendered by verifing
       * if all the information needed is present
       * and if the environment is not a folder.
       *
       * @returns {Boolean}
       */
=======
      * Verifies if deplyment internal ID should be rendered by verifing
      * if all the information needed is present
      * and if the environment is not a folder.
      *
      * @returns {Boolean}
      */
>>>>>>> upstream/master
      shouldRenderDeploymentID() {
        return !this.model.isFolder &&
          !_.isEmpty(this.model.last_deployment) &&
          this.model.last_deployment.iid !== undefined;
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
        return this.hasManualActions ||
              this.externalURL ||
              this.monitoringUrl ||
              this.hasStopAction ||
              this.canRetry;
      },
    },

    methods: {
      onClickFolder() {
        eventHub.$emit('toggleFolder', this.model);
      },
<<<<<<< HEAD
      toggleDeployBoard() {
        eventHub.$emit('toggleDeployBoard', this.model);
      },
=======
>>>>>>> upstream/master
    },
  };
</script>
<template>
  <div
    class="gl-responsive-table-row"
    :class="{
      'js-child-row environment-child-row': model.isChildren,
      'folder-row': model.isFolder,
    }"
    role="row">
    <div
      class="table-section section-10"
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
        class="deploy-board-icon"
        v-if="model.hasDeployBoard"
        @click="toggleDeployBoard">

        <i
          v-show="!model.isDeployBoardVisible"
          class="fa fa-caret-right"
          aria-hidden="true">
        </i>

        <i
          v-show="model.isDeployBoardVisible"
          class="fa fa-caret-down"
          aria-hidden="true">
        </i>
      </span>
      <a
        v-if="!model.isFolder"
        class="environment-name flex-truncate-parent table-mobile-content"
        :href="environmentPath">
        <span class="flex-truncate-child">{{ model.name }}</span>
      </a>
      <span
        v-else
        class="folder-name"
        @click="onClickFolder"
        role="button">

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

        <span class="badge">
          {{ model.size }}
        </span>
      </span>
    </div>

    <div
      class="table-section section-10 deployment-column hidden-xs hidden-sm"
      role="gridcell"
    >
      <span v-if="shouldRenderDeploymentID">
        {{ deploymentInternalId }}
      </span>

      <span v-if="!model.isFolder && deploymentHasUser">
        by
        <user-avatar-link
          class="js-deploy-user-container"
          :link-href="deploymentUser.web_url"
          :img-src="deploymentUser.avatar_url"
          :img-alt="userImageAltDescription"
          :tooltip-text="deploymentUser.username"
        />
      </span>
    </div>

    <div
      class="table-section section-15 hidden-xs hidden-sm"
      role="gridcell"
    >
      <a
        v-if="shouldRenderBuildName"
        class="build-link flex-truncate-parent"
        :href="buildPath"
      >
        <span class="flex-truncate-child">{{ buildName }}</span>
      </a>
    </div>

    <div
      v-if="!model.isFolder"
      class="table-section section-25"
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

        <actions-component
          v-if="hasManualActions && canCreateDeployment"
          :actions="manualActions"
        />

        <external-url-component
          v-if="externalURL && canReadEnvironment"
          :external-url="externalURL"
        />

        <monitoring-button-component
          v-if="monitoringUrl && canReadEnvironment"
          :monitoring-url="monitoringUrl"
        />

        <terminal-button-component
          v-if="model && model.terminal_path"
          :terminal-path="model.terminal_path"
        />

        <stop-component
          v-if="hasStopAction && canCreateDeployment"
          :stop-url="model.stop_path"
        />

        <rollback-component
          v-if="canRetry && canCreateDeployment"
          :is-last-deployment="isLastDeployment"
          :retry-url="retryUrl"
        />
      </div>
    </div>
  </div>
</template>
