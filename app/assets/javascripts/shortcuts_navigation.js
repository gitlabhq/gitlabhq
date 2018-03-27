import Mousetrap from 'mousetrap';
import findAndFollowLink from './shortcuts_dashboard_navigation';
import Shortcuts from './shortcuts';

export default class ShortcutsNavigation extends Shortcuts {
  constructor() {
    super();

    Mousetrap.bind('g p', () => findAndFollowLink('.shortcuts-project'));
    Mousetrap.bind('g e', () => findAndFollowLink('.shortcuts-project-activity'));
    Mousetrap.bind('g f', () => findAndFollowLink('.shortcuts-tree'));
    Mousetrap.bind('g c', () => findAndFollowLink('.shortcuts-commits'));
    Mousetrap.bind('g j', () => findAndFollowLink('.shortcuts-builds'));
    Mousetrap.bind('g n', () => findAndFollowLink('.shortcuts-network'));
    Mousetrap.bind('g d', () => findAndFollowLink('.shortcuts-repository-charts'));
    Mousetrap.bind('g i', () => findAndFollowLink('.shortcuts-issues'));
    Mousetrap.bind('g b', () => findAndFollowLink('.shortcuts-issue-boards'));
    Mousetrap.bind('g m', () => findAndFollowLink('.shortcuts-merge_requests'));
    Mousetrap.bind('g t', () => findAndFollowLink('.shortcuts-todos'));
    Mousetrap.bind('g w', () => findAndFollowLink('.shortcuts-wiki'));
    Mousetrap.bind('g s', () => findAndFollowLink('.shortcuts-snippets'));
    Mousetrap.bind('i', () => findAndFollowLink('.shortcuts-new-issue'));

    this.enabledHelp.push('.hidden-shortcut.project');
  }
}
