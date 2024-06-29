import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import GitlabSlackApplication from './components/gitlab_slack_application.vue';

export default () => {
  const el = document.querySelector('.js-gitlab-slack-application');

  if (!el) return null;

  const { projects, isSignedIn, signInPath, slackLinkPath, gitlabLogoPath, slackLogoPath } =
    el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(GitlabSlackApplication, {
        props: {
          projects: JSON.parse(projects),
          isSignedIn: parseBoolean(isSignedIn),
          signInPath,
          slackLinkPath,
          gitlabLogoPath,
          slackLogoPath,
        },
      });
    },
  });
};
