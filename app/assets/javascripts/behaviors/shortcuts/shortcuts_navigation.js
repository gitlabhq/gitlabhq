import Mousetrap from 'mousetrap';
import findAndFollowLink from '../../lib/utils/navigation_utility';
import {
  keysFor,
  GO_TO_PROJECT_OVERVIEW,
  GO_TO_PROJECT_ACTIVITY_FEED,
  GO_TO_PROJECT_RELEASES,
  GO_TO_PROJECT_FILES,
  GO_TO_PROJECT_COMMITS,
  GO_TO_PROJECT_JOBS,
  GO_TO_PROJECT_REPO_GRAPH,
  GO_TO_PROJECT_REPO_CHARTS,
  GO_TO_PROJECT_ISSUES,
  GO_TO_PROJECT_ISSUE_BOARDS,
  GO_TO_PROJECT_MERGE_REQUESTS,
  GO_TO_PROJECT_WIKI,
  GO_TO_PROJECT_SNIPPETS,
  GO_TO_PROJECT_KUBERNETES,
  GO_TO_PROJECT_ENVIRONMENTS,
  GO_TO_PROJECT_METRICS,
  NEW_ISSUE,
} from './keybindings';
import Shortcuts from './shortcuts';

export default class ShortcutsNavigation extends Shortcuts {
  constructor() {
    super();

    Mousetrap.bind(keysFor(GO_TO_PROJECT_OVERVIEW), () => findAndFollowLink('.shortcuts-project'));
    Mousetrap.bind(keysFor(GO_TO_PROJECT_ACTIVITY_FEED), () =>
      findAndFollowLink('.shortcuts-project-activity'),
    );
    Mousetrap.bind(keysFor(GO_TO_PROJECT_RELEASES), () =>
      findAndFollowLink('.shortcuts-project-releases'),
    );
    Mousetrap.bind(keysFor(GO_TO_PROJECT_FILES), () => findAndFollowLink('.shortcuts-tree'));
    Mousetrap.bind(keysFor(GO_TO_PROJECT_COMMITS), () => findAndFollowLink('.shortcuts-commits'));
    Mousetrap.bind(keysFor(GO_TO_PROJECT_JOBS), () => findAndFollowLink('.shortcuts-builds'));
    Mousetrap.bind(keysFor(GO_TO_PROJECT_REPO_GRAPH), () =>
      findAndFollowLink('.shortcuts-network'),
    );
    Mousetrap.bind(keysFor(GO_TO_PROJECT_REPO_CHARTS), () =>
      findAndFollowLink('.shortcuts-repository-charts'),
    );
    Mousetrap.bind(keysFor(GO_TO_PROJECT_ISSUES), () => findAndFollowLink('.shortcuts-issues'));
    Mousetrap.bind(keysFor(GO_TO_PROJECT_ISSUE_BOARDS), () =>
      findAndFollowLink('.shortcuts-issue-boards'),
    );
    Mousetrap.bind(keysFor(GO_TO_PROJECT_MERGE_REQUESTS), () =>
      findAndFollowLink('.shortcuts-merge_requests'),
    );
    Mousetrap.bind(keysFor(GO_TO_PROJECT_WIKI), () => findAndFollowLink('.shortcuts-wiki'));
    Mousetrap.bind(keysFor(GO_TO_PROJECT_SNIPPETS), () => findAndFollowLink('.shortcuts-snippets'));
    Mousetrap.bind(keysFor(GO_TO_PROJECT_KUBERNETES), () =>
      findAndFollowLink('.shortcuts-kubernetes'),
    );
    Mousetrap.bind(keysFor(GO_TO_PROJECT_ENVIRONMENTS), () =>
      findAndFollowLink('.shortcuts-environments'),
    );
    Mousetrap.bind(keysFor(GO_TO_PROJECT_METRICS), () => findAndFollowLink('.shortcuts-metrics'));
    Mousetrap.bind(keysFor(NEW_ISSUE), () => findAndFollowLink('.shortcuts-new-issue'));
  }
}
