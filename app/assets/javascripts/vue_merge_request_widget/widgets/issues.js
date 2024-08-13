/* eslint-disable */
import { STATUS_CLOSED } from '~/issues/constants';
import { EXTENSION_ICONS } from '../constants';
import issuesCollapsedQuery from './issues_collapsed.query.graphql';
import issuesQuery from './issues.query.graphql';
import { n__, sprintf } from '~/locale';

export default {
  // Give the extension a name
  // Make it easier to track in Vue dev tools
  name: 'WidgetIssues',
  i18n: {
    label: 'Issues',
    loading: 'Loading issues...',
  },
  // Add an array of props
  // These then get mapped to values stored in the MR Widget store
  props: ['targetProjectFullPath', 'conflictsDocsPath'],
  // Add any extra computed props in here
  computed: {
    // Small summary text to be displayed in the collapsed state
    // Receives the collapsed data as an argument
    summary(count) {
      return sprintf(
        n__(
          'ciReport|Load performance test metrics detected %{strong_start}%{changesFound}%{strong_end} change',
          'ciReport|Load performance test metrics detected %{strong_start}%{changesFound}%{strong_end} changes',
          count,
        ),
        { changesFound: count },
      );
    },
    // Status icon to be used next to the summary text
    // Receives the collapsed data as an argument
    statusIcon(count) {
      return EXTENSION_ICONS.failed;
    },
    // Tertiary action buttons that will take the user elsewhere
    // in the GitLab app
    tertiaryButtons() {
      return [
        {
          text: 'Click me',
          onClick() {
            console.log('Hello world');
          },
        },
        {
          text: 'Full report',
          href: this.conflictsDocsPath,
          target: '_blank',
          trackFullReportClicked: true,
        },
      ];
    },
    shouldCollapse() {
      return true;
    },
  },
  methods: {
    // Fetches the collapsed data
    // Ideally, this request should return the smallest amount of data possible
    // Receives an object of all the props passed in to the extension
    fetchCollapsedData({ targetProjectFullPath }) {
      return this.$apollo
        .query({ query: issuesCollapsedQuery, variables: { projectPath: targetProjectFullPath } })
        .then(({ data }) => data.project.issues.count);
    },
    // Fetches the full data when the extension is expanded
    // Receives an object of all the props passed in to the extension
    fetchFullData({ targetProjectFullPath }) {
      return this.$apollo
        .query({ query: issuesQuery, variables: { projectPath: targetProjectFullPath } })
        .then(({ data }) => {
          // Return some transformed data to be rendered in the expanded state
          return data.project.issues.nodes.map((issue, i) => ({
            id: issue.id, // Required: The ID of the object
            header: ['New', 'This is an %{strong_start}issue%{strong_end} row'],
            text: '%{critical_start}1 Critical%{critical_end}, %{danger_start}1 High%{danger_end}, and %{strong_start}1 Other%{strong_end}. %{small_start}Some smaller text%{small_end}', // Required: The text to get used on each row
            subtext:
              'Reported resource changes: %{strong_start}2%{strong_end} to add, 0 to change, 0 to delete', // Optional: The sub-text to get displayed below each rows main content
            // Icon to get rendered on the side of each row
            icon: {
              // Required: Name maps to an icon in GitLabs SVG
              name: issue.state === STATUS_CLOSED ? EXTENSION_ICONS.error : EXTENSION_ICONS.success,
            },
            // Badges get rendered next to the text on each row
            // badge: issue.state === 'closed' && {
            //   text: 'Closed', // Required: Text to be used inside of the badge
            //   // variant: 'info', // Optional: The variant of the badge, maps to GitLab UI variants
            // },
            // Each row can have its own link that will take the user elsewhere
            // link: {
            //   href: 'https://google.com', // Required: href for the link
            //   text: 'Link text', // Required: Text to be used inside the link
            // },
            actions: [{ text: 'Full report', href: 'https://gitlab.com', target: '_blank' }],
            children: [
              {
                id: `child-${issue.id}`,
                header: 'New',
                text: '%{critical_start}1 Critical%{critical_end}',
                icon: {
                  name: EXTENSION_ICONS.error,
                },
              },
            ],
          }));
        });
    },
  },
};
