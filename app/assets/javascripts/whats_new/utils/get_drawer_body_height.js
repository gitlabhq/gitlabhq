export const getDrawerBodyHeight = (drawer) => {
  const drawerViewableHeight = drawer.clientHeight - drawer.getBoundingClientRect().top;
  const drawerHeaderHeight = drawer.querySelector('.gl-drawer-header').clientHeight;

  return drawerViewableHeight - drawerHeaderHeight;
};
