import { GlTabsBehavior, HISTORY_TYPE_HASH } from '~/tabs';

export default class EmptyProject {
  constructor() {
    const configureGitTabsEl = document.querySelector('.js-configure-git-tabs');
    const emptyProjectTabsEl = document.querySelector('.js-empty-project-tabs');

    // Neither nav renders without push access, and the protocol nav also needs SSH enabled.
    [configureGitTabsEl, emptyProjectTabsEl].filter(Boolean).forEach((el) => {
      // eslint-disable-next-line no-new
      new GlTabsBehavior(el, { history: HISTORY_TYPE_HASH });
    });
  }
}
