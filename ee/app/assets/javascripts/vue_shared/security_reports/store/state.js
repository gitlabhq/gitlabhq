import { s__ } from '~/locale';

export default () => ({
  summaryCounts: {
    added: 0,
    fixed: 0,
  },

  blobPath: {
    head: null,
    base: null,
  },

  vulnerabilityFeedbackPath: null,
  vulnerabilityFeedbackHelpPath: null,
  pipelineId: null,

  sast: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    allIssues: [],
  },
  sastContainer: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
  },
  dast: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
  },

  dependencyScanning: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    allIssues: [],
  },

  modal: {
    title: null,

    // Dynamic data rendered for each issue
    data: {
      description: {
        value: null,
        text: s__('ciReport|Description'),
        isLink: false,
      },
      file: {
        value: null,
        url: null,
        text: s__('ciReport|File'),
        isLink: true,
      },
      namespace: {
        value: null,
        text: s__('ciReport|Namespace'),
        isLink: false,
      },
      identifier: {
        value: null,
        url: null,
        text: s__('ciReport|Identifier'),
        isLink: false,
      },
      severity: {
        value: null,
        text: s__('ciReport|Severity'),
        isLink: false,
      },
      solution: {
        value: null,
        text: s__('ciReport|Solution'),
        isLink: false,
      },
      confidenceLevel: {
        value: null,
        text: s__('ciReport|Confidence Level'),
        isLink: false,
      },
      source: {
        value: null,
        text: s__('ciReport|Source'),
        isLink: true,
      },
      instances: {
        value: [],
        text: s__('ciReport|Instances'),
        isLink: false,
      },
    },
    learnMoreUrl: null,

    vulnerability: {
      isDimissed: false,
      hasIssue: false,
    },

    isCreatingNewIssue: false,
    isDismissingIssue: false,

    error: null,
  },
});
