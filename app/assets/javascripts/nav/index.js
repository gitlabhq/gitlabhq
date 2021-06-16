// With combined_menu feature flag, there's a benefit to splitting up the import
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
