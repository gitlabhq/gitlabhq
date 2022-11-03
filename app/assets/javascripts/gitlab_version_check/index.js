import Vue from 'vue';
import * as Sentry from '@sentry/browser';
import { parseBoolean } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import GitlabVersionCheckBadge from './components/gitlab_version_check_badge.vue';

const mountGitlabVersionCheckBadge = ({ el, status }) => {
  const { size } = el.dataset;
  const actionable = parseBoolean(el.dataset.actionable);

  return new Vue({
    el,
    render(createElement) {
      return createElement(GitlabVersionCheckBadge, {
        props: {
          size,
          actionable,
          status,
        },
      });
    },
  });
};

export default async () => {
  const versionCheckBadges = [...document.querySelectorAll('.js-gitlab-version-check-badge')];

  // If there are no version check elements, exit out
  if (versionCheckBadges?.length <= 0) {
    return null;
  }

  const status = await axios
    .get(joinPaths('/', gon.relative_url_root, '/admin/version_check.json'))
    .then((res) => {
      return res.data?.severity;
    })
    .catch((e) => {
      Sentry.captureException(e);
      return null;
    });

  // If we don't have a status there is nothing to render
  if (status) {
    return versionCheckBadges.map((el) => mountGitlabVersionCheckBadge({ el, status }));
  }

  return null;
};
