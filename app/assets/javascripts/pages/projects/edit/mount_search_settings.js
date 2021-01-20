const mountSearchSettings = async () => {
  const el = document.querySelector('.js-search-settings-app');

  if (el) {
    const { default: initSearch } = await import(
      /* webpackChunkName: 'search_settings' */ '~/search_settings'
    );
    initSearch({ el });
  }
};

export default mountSearchSettings;
