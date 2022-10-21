import Vue from 'vue';
import GitlabVersionCheck from '~/vue_shared/components/gitlab_version_check.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

const mountGitlabVersionCheck = (el) => {
  const { size } = el.dataset;
  const actionable = parseBoolean(el.dataset.actionable);

  return new Vue({
    el,
    render(createElement) {
      return createElement(GitlabVersionCheck, {
        props: {
          size,
          actionable,
        },
      });
    },
  });
};

export default () =>
  [...document.querySelectorAll('.js-gitlab-version-check')].map(mountGitlabVersionCheck);
