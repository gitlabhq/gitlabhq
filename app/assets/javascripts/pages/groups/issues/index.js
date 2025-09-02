import { WORKSPACE_GROUP } from '~/issues/constants';

const isWorkItemsEnabled = Boolean(
  document.querySelector('#js-work-items')?.dataset?.isGroupIssuesList,
);

async function initializeApp() {
  if (isWorkItemsEnabled) {
    const { initWorkItemsRoot } = await import('~/work_items');
    initWorkItemsRoot({ workspaceType: WORKSPACE_GROUP });
  } else {
    const { mountIssuesListApp } = await import('~/issues/list');
    await mountIssuesListApp();
  }
}

initializeApp();
