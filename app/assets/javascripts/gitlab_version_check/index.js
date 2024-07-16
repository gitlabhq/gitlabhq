import Vue from 'vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import GitlabVersionCheckBadge from './components/gitlab_version_check_badge.vue';
import SecurityPatchUpgradeAlertModal from './components/security_patch_upgrade_alert_modal.vue';

const mountGitlabVersionCheckBadge = (el) => {
  const { version } = el.dataset;
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

const mountSecurityPatchUpgradeAlertModal = (el) => {
  const { currentVersion, version } = el.dataset;

  try {
    const { details, latestStableVersions, latestStableVersionOfMinor } =
      convertObjectPropsToCamelCase(JSON.parse(version));

    return new Vue({
      el,
      render(createElement) {
        return createElement(SecurityPatchUpgradeAlertModal, {
          props: {
            currentVersion,
            details,
            latestStableVersions,
            latestStableVersionOfMinor,
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

  const securityPatchUpgradeAlertModal = document.getElementById(
    'js-security-patch-upgrade-alert-modal',
  );
  const versionCheckBadges = [...document.querySelectorAll('.js-gitlab-version-check-badge')];

  if (securityPatchUpgradeAlertModal) {
    renderedApps.push(mountSecurityPatchUpgradeAlertModal(securityPatchUpgradeAlertModal));
  }

  renderedApps.push(...versionCheckBadges.map((el) => mountGitlabVersionCheckBadge(el)));

  return renderedApps;
};
