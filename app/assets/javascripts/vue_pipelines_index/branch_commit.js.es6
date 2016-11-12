/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueBranchCommit = Vue.extend({
    props: ['pipeline'],
    computed: {
      mailto() {
        return `mailto:${this.pipeline.commit.author_email}`;
      },
      alt() {
        return `${this.pipeline.commit.author_name}'s avatar`;
      },
    },
    template: `
      <td class="branch-commit">
        <div class="icon-container">
          <i class="fa fa-code-fork"></i>
          </div>
          <!-- ** will need branch_url for this branch ** -->
          <a
            class="monospace branch-name"
            :href='pipeline.ref.url'
          >
            {{pipeline.ref.name}}
          </a>
          <div class="icon-container commit-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
            <path fill="#8F8F8F" fill-rule="evenodd" d="M28.7769836,18 C27.8675252,13.9920226 24.2831748,11 20,11 C15.7168252,11 12.1324748,13.9920226 11.2230164,18 L4.0085302,18 C2.90195036,18 2,18.8954305 2,20 C2,21.1122704 2.8992496,22 4.0085302,22 L11.2230164,22 C12.1324748,26.0079774 15.7168252,29 20,29 C24.2831748,29 27.8675252,26.0079774 28.7769836,22 L35.9914698,22 C37.0980496,22 38,21.1045695 38,20 C38,18.8877296 37.1007504,18 35.9914698,18 L28.7769836,18 L28.7769836,18 Z M20,25 C22.7614237,25 25,22.7614237 25,20 C25,17.2385763 22.7614237,15 20,15 C17.2385763,15 15,17.2385763 15,20 C15,22.7614237 17.2385763,25 20,25 L20,25 Z"></path>
          </svg>
        </div>
        <a
          class="commit-id monospace"
          :href='pipeline.commit.commit_url'
        >
          {{pipeline.commit.short_id}}
        </a>
        <p class="commit-title">
          <a
            :href='mailto'
          >
            <!-- ** will still need gravatar url ** -->
            <img
              class="avatar has-tooltip s20 hidden-xs"
              :alt='alt'
              :title='pipeline.commit.author_name'
              data-container="body"
              src="http://www.gravatar.com/avatar/80d3b651b4be1f1db39435c2d11f1f23?s=40&amp;d=identicon"
            >
          </a>
          <a
            class="commit-row-message"
            :href='pipeline.commit.commit_url'
          >
            {{pipeline.commit.title}}
          </a>
        </p>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
