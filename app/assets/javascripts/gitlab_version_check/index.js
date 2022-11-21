import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import GitlabVersionCheckBadge from './components/gitlab_version_check_badge.vue';

const mountGitlabVersionCheckBadge = (el) => {
  const { size, version } = el.dataset;
  const actionable = parseBoolean(el.dataset.actionable);

  try {
    const { severity } = JSON.parse(version);

    // If no severity (status) data don't worry about rendering
    if (!severity) {
      return null;
    }

    return new Vue({
      el,
      render(createElement) {
        return createElement(GitlabVersionCheckBadge, {
          props: {
            size,
            actionable,
            status: severity,
          },
        });
      },
    });
  } catch {
    return null;
  }
};

export default () => {
  const versionCheckBadges = [...document.querySelectorAll('.js-gitlab-version-check-badge')];

  return versionCheckBadges.map((el) => mountGitlabVersionCheckBadge(el));
};
