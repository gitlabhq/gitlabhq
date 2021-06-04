function onSidebarLinkClick() {
  const setDataTrackAction = (element, action) => {
    element.setAttribute('data-track-action', action);
  };

  const setDataTrackExtra = (element, value) => {
    const SIDEBAR_COLLAPSED = 'Collapsed';
    const SIDEBAR_EXPANDED = 'Expanded';
    const sidebarCollapsed = document
      .querySelector('.nav-sidebar')
      .classList.contains('js-sidebar-collapsed')
      ? SIDEBAR_COLLAPSED
      : SIDEBAR_EXPANDED;

    element.setAttribute(
      'data-track-extra',
      JSON.stringify({ sidebar_display: sidebarCollapsed, menu_display: value }),
    );
  };

  const EXPANDED = 'Expanded';
  const FLY_OUT = 'Fly out';
  const CLICK_MENU_ACTION = 'click_menu';
  const CLICK_MENU_ITEM_ACTION = 'click_menu_item';
  const parentElement = this.parentNode;
  const subMenuList = parentElement.closest('.sidebar-sub-level-items');

  if (subMenuList) {
    const isFlyOut = subMenuList.classList.contains('fly-out-list') ? FLY_OUT : EXPANDED;

    setDataTrackExtra(parentElement, isFlyOut);
    setDataTrackAction(parentElement, CLICK_MENU_ITEM_ACTION);
  } else {
    const isFlyOut = parentElement.classList.contains('is-showing-fly-out') ? FLY_OUT : EXPANDED;

    setDataTrackExtra(parentElement, isFlyOut);
    setDataTrackAction(parentElement, CLICK_MENU_ACTION);
  }
}
export const initSidebarTracking = () => {
  document.querySelectorAll('.nav-sidebar li[data-track-label] > a').forEach((link) => {
    link.addEventListener('click', onSidebarLinkClick);
  });
};
