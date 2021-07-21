// TODO: With the combined_menu feature flag removed, there's likely a better
// way to slice up the async import (i.e., include trigger in main bundle, but
// async import subviews. Don't do this at the cost of UX).
// See https://gitlab.com/gitlab-org/gitlab/-/issues/336042
const importModule = () => import(/* webpackChunkName: 'top_nav' */ './mount');

const tryMountTopNav = async () => {
  const el = document.getElementById('js-top-nav');

  if (!el) {
    return;
  }

  const { mountTopNav } = await importModule();

  mountTopNav(el);
};

const tryMountTopNavResponsive = async () => {
  const el = document.getElementById('js-top-nav-responsive');

  if (!el) {
    return;
  }

  const { mountTopNavResponsive } = await importModule();

  mountTopNavResponsive(el);
};

export const initTopNav = async () => Promise.all([tryMountTopNav(), tryMountTopNavResponsive()]);
