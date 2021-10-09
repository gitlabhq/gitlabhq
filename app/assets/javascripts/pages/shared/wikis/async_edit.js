export const mountApplications = async () => {
  const el = document.querySelector('.js-wiki-edit-page');

  if (el) {
    const { mountApplications: mountEditApplications } = await import(
      /* webpackChunkName: 'wiki_edit' */ './edit'
    );

    mountEditApplications();
  }
};
