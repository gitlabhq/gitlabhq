import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import GitlabVersionCheckBadge from './components/gitlab_version_check_badge.vue';
import SecurityPatchUpgradeAlert from './components/security_patch_upgrade_alert.vue';

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

const mountSecurityPatchUpgradeAlert = (el) => {
  const { currentVersion } = el.dataset;

  try {
    return new Vue({
      el,
      render(createElement) {
        return createElement(SecurityPatchUpgradeAlert, {
          props: {
            currentVersion,
          },
        });
      },
    });
  } catch {
    return null;
  }
};

export default () => {
  const renderedApps = [];

  const securityPatchUpgradeAlert = document.getElementById('js-security-patch-upgrade-alert');
  const versionCheckBadges = [...document.querySelectorAll('.js-gitlab-version-check-badge')];

  if (securityPatchUpgradeAlert) {
    renderedApps.push(mountSecurityPatchUpgradeAlert(securityPatchUpgradeAlert));
  }

  renderedApps.push(...versionCheckBadges.map((el) => mountGitlabVersionCheckBadge(el)));

  return renderedApps;
};
