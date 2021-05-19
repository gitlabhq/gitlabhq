export const initTopNav = async () => {
  const el = document.getElementById('js-top-nav');

  if (!el) {
    return;
  }

  // With combined_menu feature flag, there's a benefit to splitting up the import
  const { mountTopNav } = await import(/* webpackChunkName: 'top_nav' */ './mount');

  mountTopNav(el);
};
