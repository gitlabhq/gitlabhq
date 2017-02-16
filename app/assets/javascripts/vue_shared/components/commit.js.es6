/* global Vue */
window.Vue = require('vue');

(() => {
  window.gl = window.gl || {};

  window.gl.CommitComponent = Vue.component('commit-component', {

    props: {
      /**
       * Indicates the existance of a tag.
       * Used to render the correct icon, if true will render `fa-tag` icon,
       * if false will render `fa-code-fork` icon.
       */
      tag: {
        type: Boolean,
        required: false,
        default: false,
      },

      /**
       * If provided is used to render the branch name and url.
       * Should contain the following properties:
       * name
       * ref_url
       */
      commitRef: {
        type: Object,
        required: false,
        default: () => ({}),
      },

      /**
       * Used to link to the commit sha.
       */
      commitUrl: {
        type: String,
        required: false,
        default: '',
      },

      /**
       * Used to show the commit short sha that links to the commit url.
       */
      shortSha: {
        type: String,
        required: false,
        default: '',
      },

      /**
       * If provided shows the commit tile.
       */
      title: {
        type: String,
        required: false,
        default: '',
      },

      /**
       * If provided renders information about the author of the commit.
       * When provided should include:
       * `avatar_url` to render the avatar icon
       * `web_url` to link to user profile
       * `username` to render alt and title tags
       */
      author: {
        type: Object,
        required: false,
        default: () => ({}),
      },

      commitIconSvg: {
        type: String,
        required: false,
      },
    },

    computed: {
      /**
       * Used to verify if all the properties needed to render the commit
       * ref section were provided.
       *
       * TODO: Improve this! Use lodash _.has when we have it.
       *
       * @returns {Boolean}
       */
      hasCommitRef() {
        return this.commitRef && this.commitRef.name && this.commitRef.ref_url;
      },

      /**
       * Used to verify if all the properties needed to render the commit
       * author section were provided.
       *
       * TODO: Improve this! Use lodash _.has when we have it.
       *
       * @returns {Boolean}
       */
      hasAuthor() {
        return this.author &&
          this.author.avatar_url &&
          this.author.web_url &&
          this.author.username;
      },

      /**
       * If information about the author is provided will return a string
       * to be rendered as the alt attribute of the img tag.
       *
       * @returns {String}
       */
      userImageAltDescription() {
        return this.author &&
          this.author.username ? `${this.author.username}'s avatar` : null;
      },
    },

    template: `
      <div class="branch-commit">

        <div v-if="hasCommitRef" class="icon-container">
          <i v-if="tag" class="fa fa-tag"></i>
          <i v-if="!tag" class="fa fa-code-fork"></i>
        </div>

        <a v-if="hasCommitRef"
          class="monospace branch-name"
          :href="commitRef.ref_url">
          {{commitRef.name}}
        </a>

        <div v-html="commitIconSvg" class="commit-icon js-commit-icon"></div>

        <a class="commit-id monospace"
          :href="commitUrl">
          {{shortSha}}
        </a>

        <p class="commit-title">
          <span v-if="title">
            <a v-if="hasAuthor"
              class="avatar-image-container"
              :href="author.web_url">
              <img
                class="avatar has-tooltip s20"
                :src="author.avatar_url"
                :alt="userImageAltDescription"
                :title="author.username" />
            </a>

            <a class="commit-row-message"
              :href="commitUrl">
              {{title}}
            </a>
          </span>
          <span v-else>
            Cant find HEAD commit for this branch
          </span>
        </p>
      </div>
    `,
  });
})();
