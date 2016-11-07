/* globals Vue */
/* eslint-disable no-param-reassign, no-return-assign */
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

    template: '#environment-item-template',

    props: {
      model: Object,
    },

    data() {
      return {
        open: false,
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
        return this.$options.hasKey(this.model, 'children') && this.model.children.length > 0;
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
        return this.$options.hasKey(this.model, 'children') && this.model.children.length;
      },

      /**
       * Returns the value of the `last?` key sent in the API.
       * Used to know wich title to render when the environment can be re-deployed
       *
       * @returns {Boolean}
       */
      isLast() {
        return this.$options.hasKey(this.model, 'last_deployment') && this.model.last_deployment['last?'];
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
       * @returns {Boolean}  description
       */
      hasManualActions() {
        return this.$options.hasKey(this.model, 'manual_actions') && this.model.manual_actions.length;
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
        return this.hasLastDeploymentKey && this.model.last_deployment && this.$options.hasKey(this.model.last_deployment, 'deployable');
      },

      createdDate() {
        return $.timeago(this.model.created_at);
      },

      manualActions() {
        this.model.manual_actions.map(action => action.name = gl.text.humanize(action.name));
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
  });
})();
