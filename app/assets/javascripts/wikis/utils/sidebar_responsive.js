// This utility uses direct DOM manipulation because the wiki sidebar and
// wiki content are currently separate Vue apps with no shared state.
// Once they are unified into a single app, this should be refactored to
// use reactive state and emitted events instead. See:
// https://gitlab.com/gitlab-org/gitlab/-/work_items/587313

function isSidebarFixed(sidebarElement) {
  return window.getComputedStyle(sidebarElement).position === 'fixed';
}

function isSidebarExpanded(sidebarElement) {
  return sidebarElement.classList.contains('sidebar-expanded');
}

function isSidebarOverlappingContent(sidebarElement, contentElement) {
  // Early return: a non-fixed sidebar is in normal document flow and cannot overlap content.
  // This avoids unnecessary getBoundingClientRect calls.
  if (!isSidebarFixed(sidebarElement) || !isSidebarExpanded(sidebarElement)) {
    return false;
  }

  const sidebarContainer = sidebarElement.querySelector('.sidebar-container');
  if (!sidebarContainer) return false;

  const sidebarRight = sidebarContainer.getBoundingClientRect().right;
  const contentLeft = contentElement.getBoundingClientRect().left;

  return sidebarRight > contentLeft;
}

export function observeSidebarResponsiveness(onAutoClose) {
  const contentElement = document.querySelector('.wiki-page-details');
  const sidebarElement = document.querySelector('.wiki-sidebar');

  if (!contentElement || !sidebarElement) {
    return () => {};
  }

  const check = () => {
    if (isSidebarOverlappingContent(sidebarElement, contentElement)) {
      onAutoClose();
    }
  };

  const resizeObserver = new ResizeObserver(check);
  resizeObserver.observe(contentElement);

  check();

  return () => {
    resizeObserver.disconnect();
  };
}
