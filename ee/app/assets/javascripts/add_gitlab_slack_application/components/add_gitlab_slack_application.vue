<script>
  import Flash from '~/flash';
  import { redirectTo } from '~/lib/utils/url_utility';

  import GitlabSlackService from '../services/gitlab_slack_service';

  export default {
    props: {
      projects: {
        type: Array,
        required: false,
        default: () => [],
      },

      isSignedIn: {
        type: Boolean,
        required: true,
      },

      gitlabForSlackGifPath: {
        type: String,
        required: true,
      },

      signInPath: {
        type: String,
        required: true,
      },

      slackLinkPath: {
        type: String,
        required: true,
      },

      gitlabLogoPath: {
        type: String,
        required: true,
      },

      slackLogoPath: {
        type: String,
        required: true,
      },

      docsPath: {
        type: String,
        required: true,
      },
    },

    data() {
      return {
        popupOpen: false,
        selectedProjectId: this.projects && this.projects.length ? this.projects[0].id : 0,
      };
    },

    computed: {
      doubleHeadedArrowSvg() {
        return gl.utils.spriteIcon('double-headed-arrow');
      },

      arrowRightSvg() {
        return gl.utils.spriteIcon('arrow-right');
      },

      hasProjects() {
        return this.projects.length > 0;
      },
    },

    methods: {
      togglePopup() {
        this.popupOpen = !this.popupOpen;
      },

      addToSlack() {
        GitlabSlackService.addToSlack(this.slackLinkPath, this.selectedProjectId)
          .then(response => redirectTo(response.data.add_to_slack_link))
          .catch(() => Flash('Unable to build Slack link.'));
      },
    },
  };
</script>

<template>
  <div>
    <div class="center append-right-default">
      <h1>GitLab for Slack</h1>
      <p>Track your GitLab projects with GitLab for Slack.</p>
    </div>

    <div
      v-once
      class="append-bottom-20 center"
    >
      <img
        :src="gitlabLogoPath"
        class="gitlab-slack-logo"
      />
      <div
        class="gitlab-slack-double-headed-arrow inline prepend-left-20 append-right-20"
        v-html="doubleHeadedArrowSvg"
      >
      </div>
      <img
        :src="slackLogoPath"
        class="gitlab-slack-logo"
      />
    </div>

    <button
      type="button"
      class="btn btn-red mx-auto js-popup-button"
      @click="togglePopup"
    >
      Add GitLab to Slack
    </button>

    <div
      v-if="popupOpen"
      class="popup gitlab-slack-popup mx-auto prepend-top-20 text-center js-popup"
    >
      <div
        v-if="isSignedIn && hasProjects"
        class="inline"
      >
        <strong>Select GitLab project to link with your Slack team</strong>

        <select
          v-model="selectedProjectId"
          class="gitlab-slack-project-select
js-project-select form-control prepend-top-10 append-bottom-10"
        >
          <option
            v-for="project in projects"
            :key="project.id"
            :value="project.id">
            {{ project.name }}
          </option>
        </select>

        <button
          type="button"
          class="btn btn-red float-right js-add-button"
          @click="addToSlack"
        >
          Add to Slack
        </button>
      </div>

      <span
        v-else-if="isSignedIn && !hasProjects"
        class="js-no-projects"
      >
        You don't have any projects available.
      </span>

      <span v-else>
        You have to
        <a
          v-once
          :href="signInPath"
          class="js-gitlab-slack-sign-in-link"
        >
          log in
        </a>
      </span>
    </div>

    <div class="center prepend-top-20 append-bottom-10 append-right-5 prepend-left-5">
      <img
        v-once
        :src="gitlabForSlackGifPath"
        class="gitlab-slack-gif"
      />
    </div>

    <div
      v-once
      class="gitlab-slack-example"
    >
      <h3 class="center">How it works</h3>

      <div class="well gitlab-slack-well mx-auto">
        <code
          class="code mx-auto append-bottom-10"
        >/gitlab &lt;project-alias&gt; issue show &lt;id&gt;</code>
        <span>
          <div
            class="gitlab-slack-right-arrow inline append-right-5"
            v-html="arrowRightSvg"
          >
          </div>
          Shows the issue with id
          <strong>&lt;id&gt;</strong>
        </span>
      </div>

      <div class="center">
        <a :href="docsPath">
          More Slack commands
        </a>
      </div>
    </div>
  </div>
</template>
