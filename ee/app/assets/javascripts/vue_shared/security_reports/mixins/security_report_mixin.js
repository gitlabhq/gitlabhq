import { s__, n__, __, sprintf } from '~/locale';

export default {
  methods: {
    sastText(newIssues = [], resolvedIssues = [], allIssues = []) {
      const text = [];

      if (!newIssues.length && !resolvedIssues.length && !allIssues.length) {
        text.push(s__('ciReport|SAST detected no security vulnerabilities'));
      } else if (!newIssues.length && !resolvedIssues.length && allIssues.length) {
        text.push(s__('ciReport|SAST detected no new security vulnerabilities'));
      } else if (newIssues.length || resolvedIssues.length) {
        text.push(s__('ciReport|SAST'));
      }

      if (resolvedIssues.length) {
        text.push(n__(
          ' improved on %d security vulnerability',
          ' improved on %d security vulnerabilities',
          resolvedIssues.length,
        ));
      }

      if (newIssues.length > 0 && resolvedIssues.length > 0) {
        text.push(__(' and'));
      }

      if (newIssues.length) {
        text.push(n__(
          ' degraded on %d security vulnerability',
          ' degraded on %d security vulnerabilities',
          newIssues.length,
        ));
      }

      return text.join('');
    },

    depedencyScanningText(newIssues = [], resolvedIssues = [], allIssues = []) {
      const text = [];

      if (!newIssues.length && !resolvedIssues.length && !allIssues.length) {
        text.push(s__('ciReport|Dependency scanning detected no security vulnerabilities'));
      } else if (!newIssues.length && !resolvedIssues.length && allIssues.length) {
        text.push(s__('ciReport|Dependency scanning detected no new security vulnerabilities'));
      } else if (newIssues.length || resolvedIssues.length) {
        text.push(s__('ciReport|Dependency scanning'));
      }

      if (resolvedIssues.length) {
        text.push(n__(
          ' improved on %d security vulnerability',
          ' improved on %d security vulnerabilities',
          resolvedIssues.length,
        ));
      }

      if (newIssues.length > 0 && resolvedIssues.length > 0) {
        text.push(__(' and'));
      }

      if (newIssues.length) {
        text.push(n__(
          ' degraded on %d security vulnerability',
          ' degraded on %d security vulnerabilities',
          newIssues.length,
        ));
      }

      return text.join('');
    },

    translateText(type) {
      return {
        error: sprintf(s__('ciReport|Failed to load %{reportName} report'), { reportName: type }),
        loading: sprintf(s__('ciReport|Loading %{reportName} report'), { reportName: type }),
      };
    },

    checkReportStatus(loading, error) {
      if (loading) {
        return 'loading';
      } else if (error) {
        return 'error';
      }

      return 'success';
    },

    sastContainerText(vulnerabilities = [], approved = [], unapproved = []) {
      if (!vulnerabilities.length) {
        return s__('ciReport|SAST:container no vulnerabilities were found');
      }

      if (!unapproved.length && approved.length) {
        return n__(
          'SAST:container found %d approved vulnerability',
          'SAST:container found %d approved vulnerabilities',
          approved.length,
        );
      } else if (unapproved.length && !approved.length) {
        return n__(
          'SAST:container found %d vulnerability',
          'SAST:container found %d vulnerabilities',
          unapproved.length,
        );
      }

      return `${n__(
        'SAST:container found %d vulnerability,',
        'SAST:container found %d vulnerabilities,',
        vulnerabilities.length,
      )} ${n__(
        'of which %d is approved',
        'of which %d are approved',
        approved.length,
      )}`;
    },

    dastText(dast = []) {
      if (dast.length) {
        return n__(
          'DAST detected %d alert by analyzing the review app',
          'DAST detected %d alerts by analyzing the review app',
          dast.length,
        );
      }

      return s__('ciReport|DAST detected no alerts by analyzing the review app');
    },

    sastContainerInformationText() {
      return sprintf(
        s__('ciReport|Unapproved vulnerabilities (red) can be marked as approved. %{helpLink}'), {
          helpLink: `<a href="https://gitlab.com/gitlab-org/clair-scanner#example-whitelist-yaml-file" target="_blank" rel="noopener noreferrer nofollow">
            ${s__('ciReport|Learn more about whitelisting')}
          </a>`,
        },
        false,
      );
    },
  },
};
