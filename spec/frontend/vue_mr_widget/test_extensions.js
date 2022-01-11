import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';

export const workingExtension = {
  name: 'WidgetTestExtension',
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
  ...workingExtension,
  enablePolling: true,
};

export const pollingErrorExtension = {
  ...collapsedDataErrorExtension,
  enablePolling: true,
};
