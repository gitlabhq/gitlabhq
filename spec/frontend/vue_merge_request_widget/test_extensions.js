import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';

export const workingExtension = (shouldCollapse = true) => ({
  name: 'WidgetTestExtension',
  props: ['targetProjectFullPath'],
  expandEvent: 'test_expand_event',
  i18n: {
    loading: 'Test extension loading...',
  },
  computed: {
    summary({ count, targetProjectFullPath } = {}) {
      return `Test extension summary count: ${count} & ${targetProjectFullPath}`;
    },
    statusIcon({ count } = {}) {
      return count > 0 ? EXTENSION_ICONS.warning : EXTENSION_ICONS.success;
    },
    shouldCollapse() {
      return shouldCollapse;
    },
  },
  methods: {
    fetchCollapsedData({ targetProjectFullPath }) {
      return Promise.resolve({ targetProjectFullPath, count: 1 });
    },
    fetchFullData() {
      return Promise.resolve([
        {
          id: 1,
          text: 'Hello world',
          icon: {
            name: EXTENSION_ICONS.failed,
          },
          badge: {
            text: 'Closed',
          },
          link: {
            href: 'https://gitlab.com',
            text: 'GitLab.com',
          },
          actions: [{ text: 'Full report', href: 'https://gitlab.com', target: '_blank' }],
        },
      ]);
    },
  },
});

export const collapsedDataErrorExtension = {
  name: 'WidgetTestCollapsedErrorExtension',
  props: ['targetProjectFullPath'],
  expandEvent: 'test_expand_event',
  computed: {
    summary({ count, targetProjectFullPath }) {
      return `Test extension summary count: ${count} & ${targetProjectFullPath}`;
    },
    statusIcon({ count }) {
      return count > 0 ? EXTENSION_ICONS.warning : EXTENSION_ICONS.success;
    },
  },
  methods: {
    fetchCollapsedData() {
      return Promise.reject(new Error('Fetch error'));
    },
    fetchFullData() {
      return Promise.resolve([
        {
          id: 1,
          text: 'Hello world',
          icon: {
            name: EXTENSION_ICONS.failed,
          },
          badge: {
            text: 'Closed',
          },
          link: {
            href: 'https://gitlab.com',
            text: 'GitLab.com',
          },
          actions: [{ text: 'Full report', href: 'https://gitlab.com', target: '_blank' }],
        },
      ]);
    },
  },
};

export const fullDataErrorExtension = {
  name: 'WidgetTestCollapsedErrorExtension',
  props: ['targetProjectFullPath'],
  expandEvent: 'test_expand_event',
  computed: {
    summary({ count, targetProjectFullPath }) {
      return `Test extension summary count: ${count} & ${targetProjectFullPath}`;
    },
    statusIcon({ count }) {
      return count > 0 ? EXTENSION_ICONS.warning : EXTENSION_ICONS.success;
    },
  },
  methods: {
    fetchCollapsedData({ targetProjectFullPath }) {
      return Promise.resolve({ targetProjectFullPath, count: 1 });
    },
    fetchFullData() {
      return Promise.reject(new Error('Fetch error'));
    },
  },
};

export const pollingExtension = {
  ...workingExtension(),
  enablePolling: true,
};

export const pollingFullDataExtension = {
  ...workingExtension(),
  enableExpandedPolling: true,
  methods: {
    fetchCollapsedData({ targetProjectFullPath }) {
      return Promise.resolve({ targetProjectFullPath, count: 1 });
    },
    fetchFullData() {
      return Promise.resolve([
        {
          headers: { 'poll-interval': 0 },
          status: HTTP_STATUS_OK,
          data: {
            id: 1,
            text: 'Hello world',
            icon: {
              name: EXTENSION_ICONS.failed,
            },
            badge: {
              text: 'Closed',
            },
            link: {
              href: 'https://gitlab.com',
              text: 'GitLab.com',
            },
            actions: [{ text: 'Full report', href: 'https://gitlab.com', target: '_blank' }],
          },
        },
      ]);
    },
  },
};

export const fullReportExtension = {
  ...workingExtension(),
  computed: {
    ...workingExtension().computed,
    tertiaryButtons() {
      return [
        {
          text: 'test',
          href: `testref`,
          target: '_blank',
          trackFullReportClicked: true,
        },
      ];
    },
  },
};

export const noTelemetryExtension = {
  ...fullReportExtension,
  telemetry: false,
};

export const multiPollingExtension = (endpointsToBePolled) => ({
  name: 'WidgetTestMultiPollingExtension',
  props: [],
  i18n: {
    loading: 'Test extension loading...',
  },
  computed: {
    summary(data) {
      return `Multi polling test extension reports: ${data?.[0]?.reports}, count: ${data.length}`;
    },
    statusIcon(data) {
      return data?.[0]?.reports === 'parsed' ? EXTENSION_ICONS.success : EXTENSION_ICONS.warning;
    },
  },
  enablePolling: true,
  methods: {
    fetchMultiData() {
      return endpointsToBePolled;
    },
  },
});

export const pollingErrorExtension = {
  ...collapsedDataErrorExtension,
  enablePolling: true,
};
