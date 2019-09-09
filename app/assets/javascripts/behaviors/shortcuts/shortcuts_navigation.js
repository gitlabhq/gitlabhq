import Mousetrap from 'mousetrap';
import findAndFollowLink from '../../lib/utils/navigation_utility';
import Shortcuts from './shortcuts';

export default class ShortcutsNavigation extends Shortcuts {
  constructor() {
    super();

    Mousetrap.bind('g p', () => findAndFollowLink('.shortcuts-project'));
    Mousetrap.bind('g v', () => findAndFollowLink('.shortcuts-project-activity'));
    Mousetrap.bind('g r', () => findAndFollowLink('.shortcuts-project-releases'));
    Mousetrap.bind('g f', () => findAndFollowLink('.shortcuts-tree'));
    Mousetrap.bind('g c', () => findAndFollowLink('.shortcuts-commits'));
    Mousetrap.bind('g j', () => findAndFollowLink('.shortcuts-builds'));
    Mousetrap.bind('g n', () => findAndFollowLink('.shortcuts-network'));
    Mousetrap.bind('g d', () => findAndFollowLink('.shortcuts-repository-charts'));
    Mousetrap.bind('g i', () => findAndFollowLink('.shortcuts-issues'));
    Mousetrap.bind('g b', () => findAndFollowLink('.shortcuts-issue-boards'));
    Mousetrap.bind('g m', () => findAndFollowLink('.shortcuts-merge_requests'));
    Mousetrap.bind('g w', () => findAndFollowLink('.shortcuts-wiki'));
    Mousetrap.bind('g s', () => findAndFollowLink('.shortcuts-snippets'));
    Mousetrap.bind('g k', () => findAndFollowLink('.shortcuts-kubernetes'));
    Mousetrap.bind('g e', () => findAndFollowLink('.shortcuts-environments'));
    Mousetrap.bind('g l', () => findAndFollowLink('.shortcuts-metrics'));
    Mousetrap.bind('i', () => findAndFollowLink('.shortcuts-new-issue'));
  }
}
