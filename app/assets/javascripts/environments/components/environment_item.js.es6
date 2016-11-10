/*= require vue_common_component/commit
/*= require ./environment_actions
/*= require ./environment_external_url
/*= require ./environment_stop
/*= require ./environment_rollback

/* globals Vue, timeago */

(() => {
  /**
   * Envrionment Item Component
   *
   * Used in a hierarchical structure to show folders with children
   * in a table.
   * Recursive component based on [Tree View](https://vuejs.org/examples/tree-view.html)
   *
   * See this [issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/22539)
   * for more information.
   */

  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  gl.environmentsList.EnvironmentItem = Vue.component('environment-item', {

    components: {
      'commit-component': window.gl.CommitComponent,
      'actions-component': window.gl.environmentsList.ActionsComponent,
      'external-url-component': window.gl.environmentsList.ExternalUrlComponent,
      'stop-component': window.gl.environmentsList.StopComponent,
      'rollback-component': window.gl.environmentsList.RollbackComponent,
    },

    props: ['model', 'can-create-deployment', 'can-read-environment'],

    data() {
      return {
        open: false,
        rowClass: {
          'children-row': this.model['vue-isChildren'],
        },
      };
    },

    computed: {

      /**
       * If an item has a `children` entry it means it is a folder.
       * Folder items have different behaviours - it is possible to toggle
       * them and show their children.
       *
       * @returns {Boolean}
       */
      isFolder() {
        return this.$options.hasKey(this.model, 'children') &&
          this.model.children.length > 0;
      },

      /**
       * If an item is inside a folder structure will return true.
       * Used for css purposes.
       *
       * @returns {Boolean|undefined}
       */
      isChildren() {
        return this.model['vue-isChildren'];
      },

      /**
       * Counts the number of environments in each folder.
       * Used to show a badge with the counter.
       *
       * @returns {Boolean}  The number of environments for the current folder
       */
      childrenCounter() {
        return this.$options.hasKey(this.model, 'children') &&
          this.model.children.length;
      },

      /**
       * Returns the value of the `last?` key sent in the API.
       * Used to know wich title to render when the environment can be re-deployed
       *
       * @returns {Boolean}
       */
      isLast() {
        return this.$options.hasKey(this.model, 'last_deployment') &&
          this.model.last_deployment['last?'];
      },

      /**
       * Verifies if `last_deployment` key exists in the current Envrionment.
       * This key is required to render most of the html - this method works has
       * an helper.
       *
       * @returns {Boolean}
       */
      hasLastDeploymentKey() {
        return this.$options.hasKey(this.model, 'last_deployment');
      },

      /**
       * Verifies is the given environment has manual actions.
       * Used to verify if we should render them or nor.
       *
       * @returns {Boolean}
       */
      hasManualActions() {
        return this.$options.hasKey(this.model, 'manual_actions') &&
          this.model.manual_actions.length > 0;
      },

      /**
       * Returns the value of the `stoppable?` key provided in the response.
       *
       * @returns {Boolean}
       */
      isStoppable() {
        return this.model['stoppable?'];
      },

      /**
       * Verifies if the `deployable` key is present in `last_deployment` key.
       * Used to verify whether we should or not render the rollback partial.
       *
       * @returns {Boolean}
       */
      canRetry() {
        return this.hasLastDeploymentKey &&
          this.model.last_deployment &&
          this.$options.hasKey(this.model.last_deployment, 'deployable');
      },

      /**
       * Human readable date.
       *
       * @returns {String}
       */
      createdDate() {
        const timeagoInstance = new timeago();

        return timeagoInstance.format(this.model.created_at);
      },

      /**
       * Returns the manual actions with the name parsed.
       *
       * @returns {Array.<Object>}
       */
      manualActions() {
        return this.model.last_deployment.manual_actions.map((action) => {
          const parsedAction = {
            name: gl.text.humanize(action.name),
            play_url: action.play_url,
          };
          return parsedAction;
        });
      },

      userImageAltDescription() {
        return `${this.model.last_deployment.user.username}'s avatar'`;
      },

      /**
       * If provided, returns the commit tag.
       *
       * @returns {String|Undefined}
       */
      commitTag() {
        if (this.model.last_deployment && this.model.last_deployment.tag) {
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
        if (this.model.last_deployment && this.model.last_deployment.ref) {
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
        if (this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.commit_url) {
          return this.model.last_deployment.commit.commit_url;
        }
        return undefined;
      },

      /**
       * If provided, returns the commit short sha.
       *
       * @returns {String|Undefined}
       */
      commitShortSha() {
        if (this.model.last_deployment &&
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
        if (this.model.last_deployment &&
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
        if (this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.author) {
          return this.model.last_deployment.commit.author;
        }

        return undefined;
      },

      retryUrl() {
        if (this.model.last_deployment &&
          this.model.last_deployment.deployable &&
          this.model.last_deployment.deployable.retry_url) {
          return this.model.last_deployment.deployable.retry_url;
        }
        return undefined;
      },

      isLastDeployment() {
        return this.model.last_deployment && this.model.last_deployment['last?'];
      },
    },

    /**
     * Helper to verify if key is present in an object.
     * Can be removed once we start using lodash.
     *
     * @param  {Object} obj
     * @param  {String} key
     * @returns {Boolean}
     */
    hasKey(obj, key) {
      return {}.hasOwnProperty.call(obj, key);
    },

    methods: {
      /**
       * Toggles the visibility of a folders' children.
       */
      toggle() {
        if (this.isFolder) {
          this.open = !this.open;
        }
      },
    },

    template: `
      <tr>
        <td v-bind:class="{ 'children-row': isChildren}" class="col-sm-2">
          <a v-if="!isFolder" class="environment-name" :href="model.environment_url">
            {{model.name}}
          </a>
          <span v-else v-on:click="toggle" class="folder-name">
            <span class="folder-icon">
              <i v-show="open" class="fa fa-caret-down"></i>
              <i v-show="!open" class="fa fa-caret-right"></i>
            </span>

            {{model.name}}

            <span class="badge">
              {{childrenCounter}}
            </span>
          </span>
        </td>

        <td class="deployment-column col-sm-2">
          <span v-if="!isFolder && model.last_deployment && model.last_deployment.iid">
            #{{model.last_deployment.iid}}

            <span v-if="model.last_deployment.user">
              by
              <a :href="model.last_deployment.user.web_url">
                <img class="avatar has-tooltip s20"
                  :src="model.last_deployment.user.avatar_url"
                  :alt="userImageAltDescription"
                  :title="model.last_deployment.user.username" />
              </a>
            </span>
          </span>
        </td>

        <td class="col-sm-2">
          <a v-if="!isFolder && model.last_deployment && model.last_deployment.deployable"
            class="build-link"
            :href="model.last_deployment.deployable.build_url">
            {{model.last_deployment.deployable.name}} #{{model.last_deployment.deployable.id}}
          </a>
        </td>

        <td class="col-sm-2">
          <div v-if="!isFolder && model.last_deployment">
            <commit-component
              :tag="commitTag"
              :ref="commitRef"
              :commit_url="commitUrl"
              :short_sha="commitShortSha"
              :title="commitTitle"
              :author="commitAuthor">
            </commit-component>
          </div>
          <p v-if="!isFolder && !model.last_deployment" class="commit-title">
            No deployments yet
          </p>
        </td>

        <td class="col-sm-1">
          <span v-if="!isFolder && model.last_deployment" class="environment-created-date-timeago">
            {{createdDate}}
          </span>
        </td>

        <td class="hidden-xs col-sm-3">
          <div v-if="!isFolder">
            <div v-if="hasManualActions && canCreateDeployment" class="inline">
              <actions-component
                :actions="manualActions">
              </actions-component>
            </div>

            <div v-if="model.external_url && canReadEnvironment" class="inline">
              <external-url-component
                :external_url="model.external_url">
              </external_url-component>
            </div>

            <div v-if="isStoppable && canCreateDeployment" class="inline">
              <stop-component
                :stop_url="model.environment_url">
              </stop-component>
            </div>

            <div v-if="canRetry && canCreateDeployment" class="inline">
              <rollback-component
                :is_last_deployment="isLastDeployment"
                :retry_url="retryUrl">
                </rollback-component>
            </div>
          </div>
        </td>
      </tr>

      <tr v-if="open && isFolder"
        is="environment-item"
        v-for="model in model.children"
        :model="model">
      </tr>
    `,
  });
})();
