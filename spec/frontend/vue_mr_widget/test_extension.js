export default {
  name: 'WidgetTestExtension',
  props: ['targetProjectFullPath'],
  computed: {
    summary({ count, targetProjectFullPath }) {
      return `Test extension summary count: ${count} & ${targetProjectFullPath}`;
    },
    statusIcon({ count }) {
      return count > 0 ? 'warning' : 'success';
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
            name: 'status_failed_borderless',
            class: 'text-danger',
          },
          badge: {
            text: 'Closed',
          },
          link: {
            href: 'https://gitlab.com',
            text: 'GitLab.com',
          },
        },
      ]);
    },
  },
};
