import { GlTabsBehavior, HISTORY_TYPE_HASH } from '~/tabs';

export default class EmptyProject {
  constructor() {
    this.configureGitTabsEl = document.querySelector('.js-configure-git-tabs');

    this.emptyProjectTabsEl = document.querySelector('.js-empty-project-tabs');

    // eslint-disable-next-line no-new
    new GlTabsBehavior(this.configureGitTabsEl, { history: HISTORY_TYPE_HASH });
    // eslint-disable-next-line no-new
    new GlTabsBehavior(this.emptyProjectTabsEl, { history: HISTORY_TYPE_HASH });
  }
}
