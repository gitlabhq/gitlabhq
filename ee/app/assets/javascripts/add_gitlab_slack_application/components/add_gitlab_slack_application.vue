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
      class="append-bottom-20 center"
      v-once
    >
      <img
        class="gitlab-slack-logo"
        :src="gitlabLogoPath"
      />
      <div
        class="gitlab-slack-double-headed-arrow inline prepend-left-20 append-right-20"
        v-html="doubleHeadedArrowSvg"
      >
      </div>
      <img
        class="gitlab-slack-logo"
        :src="slackLogoPath"
      />
    </div>

    <button
      type="button"
      class="btn btn-red center-block js-popup-button"
      @click="togglePopup"
    >
      Add GitLab to Slack
    </button>

    <div
      class="popup gitlab-slack-popup center-block prepend-top-20 text-center js-popup"
      v-if="popupOpen"
    >
      <div
        class="inline"
        v-if="isSignedIn && hasProjects"
      >
        <strong>Select GitLab project to link with your Slack team</strong>

        <select
          class="gitlab-slack-project-select
js-project-select form-control prepend-top-10 append-bottom-10"
          v-model="selectedProjectId"
        >
          <option
            v-for="project in projects"
            :key="project.id"
            :value="project.id
          ">
            {{ project.name }}
          </option>
        </select>

        <button
          type="button"
          class="btn btn-red pull-right js-add-button"
          @click="addToSlack"
        >
          Add to Slack
        </button>
      </div>

      <span
        class="js-no-projects"
        v-else-if="isSignedIn && !hasProjects"
      >
        You don't have any projects available.
      </span>

      <span v-else>
        You have to
        <a
          class="js-gitlab-slack-sign-in-link"
          v-once
          :href="signInPath"
        >
          log in
        </a>
      </span>
    </div>

    <div class="center prepend-top-20 append-bottom-10 append-right-5 prepend-left-5">
      <img
        v-once
        class="gitlab-slack-gif"
        :src="gitlabForSlackGifPath"
      />
    </div>

    <div
      class="gitlab-slack-example"
      v-once
    >
      <h3 class="center">How it works</h3>

      <div class="well gitlab-slack-well center-block">
        <code
          class="code center-block append-bottom-10"
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
