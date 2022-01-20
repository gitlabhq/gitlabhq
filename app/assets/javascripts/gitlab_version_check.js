import Vue from 'vue';
import GitlabVersionCheck from '~/vue_shared/components/gitlab_version_check.vue';

const mountGitlabVersionCheck = (el) => {
  const { size } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(GitlabVersionCheck, {
        props: {
          size,
        },
      });
    },
  });
};

export default () =>
  [...document.querySelectorAll('.js-gitlab-version-check')].map(mountGitlabVersionCheck);
