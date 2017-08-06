import { configure } from '@storybook/vue';
import { setOptions } from '@storybook/addon-options';

setOptions({
  name: 'GitLab EE',
  url: 'https://gitlab.com/gitlab-org/gitlab-ee/',
  goFullScreen: false,
  showLeftPanel: true,
  showDownPanel: true,
  showSearchBox: false,
  downPanelInRight: true,
  sortStoriesByKind: false,
  hierarchySeparator: '\\/|\\.',
});

function loadStories() {
  require('../stories/');
}

configure(loadStories, module);
