const initSearch = async () => {
  const el = document.querySelector('.js-search-settings-app');

  if (el) {
    const { default: mount } = await import(/* webpackChunkName: 'search_settings' */ './mount');
    mount({ el });
  }
};

export default initSearch;
