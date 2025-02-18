import { visitUrl, constructWebIDEPath } from '~/lib/utils/url_utility';
import findAndFollowLink, { findAndFollowChildLink } from '~/lib/utils/navigation_utility';
import {
  GO_TO_PROJECT_OVERVIEW,
  GO_TO_PROJECT_ACTIVITY_FEED,
  GO_TO_PROJECT_RELEASES,
  GO_TO_PROJECT_FILES,
  GO_TO_PROJECT_COMMITS,
  GO_TO_PROJECT_PIPELINES,
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
  GO_TO_PROJECT_WEBIDE,
  PROJECT_FILES_GO_TO_COMPARE,
  NEW_ISSUE,
} from './keybindings';

export default class ShortcutsNavigation {
  constructor(shortcuts) {
    shortcuts.addAll([
      [GO_TO_PROJECT_OVERVIEW, () => findAndFollowLink('.shortcuts-project')],
      [GO_TO_PROJECT_ACTIVITY_FEED, () => findAndFollowLink('.shortcuts-project-activity')],
      [GO_TO_PROJECT_RELEASES, () => findAndFollowLink('.shortcuts-deployments-releases')],
      [GO_TO_PROJECT_FILES, () => findAndFollowLink('.shortcuts-tree')],
      [GO_TO_PROJECT_COMMITS, () => findAndFollowLink('.shortcuts-commits')],
      [GO_TO_PROJECT_PIPELINES, () => findAndFollowLink('.shortcuts-pipelines')],
      [GO_TO_PROJECT_JOBS, () => findAndFollowLink('.shortcuts-builds')],
      [GO_TO_PROJECT_REPO_GRAPH, () => findAndFollowLink('.shortcuts-network')],
      [GO_TO_PROJECT_REPO_CHARTS, () => findAndFollowLink('.shortcuts-repository-charts')],
      [GO_TO_PROJECT_ISSUES, () => findAndFollowLink('.shortcuts-issues')],
      [GO_TO_PROJECT_ISSUE_BOARDS, () => findAndFollowLink('.shortcuts-issue-boards')],
      [GO_TO_PROJECT_MERGE_REQUESTS, () => findAndFollowLink('.shortcuts-merge_requests')],
      [GO_TO_PROJECT_WIKI, () => findAndFollowLink('.shortcuts-wiki')],
      [GO_TO_PROJECT_SNIPPETS, () => findAndFollowLink('.shortcuts-snippets')],
      [GO_TO_PROJECT_KUBERNETES, () => findAndFollowLink('.shortcuts-kubernetes')],
      [GO_TO_PROJECT_ENVIRONMENTS, () => findAndFollowLink('.shortcuts-environments')],
      [PROJECT_FILES_GO_TO_COMPARE, () => findAndFollowChildLink('.shortcuts-compare')],
      [GO_TO_PROJECT_WEBIDE, ShortcutsNavigation.navigateToWebIDE],
      [NEW_ISSUE, () => findAndFollowLink('.shortcuts-new-issue')],
    ]);
  }

  static navigateToWebIDE() {
    const path = constructWebIDEPath({
      sourceProjectFullPath: window.gl.mrWidgetData?.source_project_full_path,
      targetProjectFullPath: window.gl.mrWidgetData?.target_project_full_path,
      iid: window.gl.mrWidgetData?.iid,
    });
    if (path) {
      visitUrl(path, true);
    }
  }
}
