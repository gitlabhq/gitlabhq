import Timeago from 'timeago.js';
import '../../lib/utils/text_utility';
import ActionsComponent from './environment_actions';
import ExternalUrlComponent from './environment_external_url.vue';
import StopComponent from './environment_stop.vue';
import RollbackComponent from './environment_rollback';
import TerminalButtonComponent from './environment_terminal_button.vue';
import MonitoringButtonComponent from './environment_monitoring';
import CommitComponent from '../../vue_shared/components/commit';
import eventHub from '../event_hub';

/**
 * Envrionment Item Component
 *
 * Renders a table row for each environment.
 */
const timeagoInstance = new Timeago();

export default {
  components: {
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

    service: {
      type: Object,
      required: true,
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
      if (this.model &&
        this.model.last_deployment &&
        !this.$options.isObjectEmpty(this.model.last_deployment)) {
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
      return this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.manual_actions &&
        this.model.last_deployment.manual_actions.length > 0;
    },

    /**
     * Returns the value of the `stop_action?` key provided in the response.
     *
     * @returns {Boolean}
     */
    hasStopAction() {
      return this.model && this.model['stop_action?'];
    },

    /**
     * Verifies if the `deployable` key is present in `last_deployment` key.
     * Used to verify whether we should or not render the rollback partial.
     *
     * @returns {Boolean|Undefined}
     */
    canRetry() {
      return this.model &&
        this.hasLastDeploymentKey &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable;
    },

    /**
     * Verifies if the date to be shown is present.
     *
     * @returns {Boolean|Undefined}
     */
    canShowDate() {
      return this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable &&
        this.model.last_deployment.deployable !== undefined;
    },

    /**
     * Human readable date.
     *
     * @returns {String}
     */
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
     * Returns the manual actions with the name parsed.
     *
     * @returns {Array.<Object>|Undefined}
     */
    manualActions() {
      if (this.hasManualActions) {
        return this.model.last_deployment.manual_actions.map((action) => {
          const parsedAction = {
            name: gl.text.humanize(action.name),
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
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.user &&
        this.model.last_deployment.user.username) {
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
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.tag) {
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
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.ref) {
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
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.commit &&
        this.model.last_deployment.commit.commit_path) {
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
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.commit &&
        this.model.last_deployment.commit.short_id) {
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
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.commit &&
        this.model.last_deployment.commit.title) {
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
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.commit &&
        this.model.last_deployment.commit.author) {
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
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable &&
        this.model.last_deployment.deployable.retry_path) {
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
      return this.model && this.model.last_deployment &&
        this.model.last_deployment['last?'];
    },

    /**
     * Builds the name of the builds needed to display both the name and the id.
     *
     * @returns {String}
     */
    buildName() {
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.deployable) {
        return `${this.model.last_deployment.deployable.name} #${this.model.last_deployment.deployable.id}`;
      }
      return '';
    },

    /**
     * Builds the needed string to show the internal id.
     *
     * @returns {String}
     */
    deploymentInternalId() {
      if (this.model &&
        this.model.last_deployment &&
        this.model.last_deployment.iid) {
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
      return this.model &&
        !this.$options.isObjectEmpty(this.model.last_deployment) &&
        !this.$options.isObjectEmpty(this.model.last_deployment.user);
    },

    /**
     * Returns the user object nested with the last_deployment object.
     * Used to render the template.
     *
     * @returns {Object}
     */
    deploymentUser() {
      if (this.model &&
        !this.$options.isObjectEmpty(this.model.last_deployment) &&
        !this.$options.isObjectEmpty(this.model.last_deployment.user)) {
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
      return !this.model.isFolder &&
        !this.$options.isObjectEmpty(this.model.last_deployment) &&
        !this.$options.isObjectEmpty(this.model.last_deployment.deployable);
    },

    /**
     * Verifies the presence of all the keys needed to render the buil_path.
     *
     * @return {String}
     */
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
      return !this.model.isFolder &&
        !this.$options.isObjectEmpty(this.model.last_deployment) &&
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

    /**
     * Constructs folder URL based on the current location and the folder id.
     *
     * @return {String}
     */
    folderUrl() {
      return `${window.location.pathname}/folders/${this.model.folderName}`;
    },
  },

  /**
   * Helper to verify if certain given object are empty.
   * Should be replaced by lodash _.isEmpty - https://lodash.com/docs/4.17.2#isEmpty
   * @param  {Object} object
   * @returns {Bollean}
   */
  isObjectEmpty(object) {
    for (const key in object) { // eslint-disable-line
      if (hasOwnProperty.call(object, key)) {
        return false;
      }
    }
    return true;
  },

  methods: {
    onClickFolder() {
      eventHub.$emit('toggleFolder', this.model, this.folderUrl);
    },
  },

  template: `
    <tr :class="{ 'js-child-row': model.isChildren }">
      <td>
        <a v-if="!model.isFolder"
          class="environment-name"
          :class="{ 'prepend-left-default': model.isChildren }"
          :href="environmentPath">
          {{model.name}}
        </a>
        <span v-else
          class="folder-name"
          @click="onClickFolder"
          role="button">

          <span class="folder-icon">
            <i
              v-show="model.isOpen"
              class="fa fa-caret-down"
              aria-hidden="true" />
            <i
              v-show="!model.isOpen"
              class="fa fa-caret-right"
              aria-hidden="true"/>
          </span>

          <span class="folder-icon">
            <i class="fa fa-folder" aria-hidden="true"></i>
          </span>

          <span>
            {{model.folderName}}
          </span>

          <span class="badge">
            {{model.size}}
          </span>
        </span>
      </td>

      <td class="deployment-column">
        <span v-if="shouldRenderDeploymentID">
          {{deploymentInternalId}}
        </span>

        <span v-if="!model.isFolder && deploymentHasUser">
          by
          <a :href="deploymentUser.web_url" class="js-deploy-user-container">
            <img class="avatar has-tooltip s20"
              :src="deploymentUser.avatar_url"
              :alt="userImageAltDescription"
              :title="deploymentUser.username" />
          </a>
        </span>
      </td>

      <td class="environments-build-cell">
        <a v-if="shouldRenderBuildName"
          class="build-link"
          :href="buildPath">
          {{buildName}}
        </a>
      </td>

      <td>
        <div v-if="!model.isFolder && hasLastDeploymentKey" class="js-commit-component">
          <commit-component
            :tag="commitTag"
            :commit-ref="commitRef"
            :commit-url="commitUrl"
            :short-sha="commitShortSha"
            :title="commitTitle"
            :author="commitAuthor"/>
        </div>
        <p v-if="!model.isFolder && !hasLastDeploymentKey" class="commit-title">
          No deployments yet
        </p>
      </td>

      <td>
        <span v-if="!model.isFolder && canShowDate"
          class="environment-created-date-timeago">
          {{createdDate}}
        </span>
      </td>

      <td class="environments-actions">
        <div v-if="!model.isFolder" class="btn-group pull-right" role="group">
          <actions-component v-if="hasManualActions && canCreateDeployment"
            :service="service"
            :actions="manualActions"/>

          <external-url-component v-if="externalURL && canReadEnvironment"
            :external-url="externalURL"/>

          <monitoring-button-component v-if="monitoringUrl && canReadEnvironment"
            :monitoring-url="monitoringUrl"/>

          <terminal-button-component v-if="model && model.terminal_path"
            :terminal-path="model.terminal_path"/>

          <stop-component v-if="hasStopAction && canCreateDeployment"
            :stop-url="model.stop_path"
            :service="service"/>

          <rollback-component v-if="canRetry && canCreateDeployment"
            :is-last-deployment="isLastDeployment"
            :retry-url="retryUrl"
            :service="service"/>
        </div>
      </td>
    </tr>
  `,
};
