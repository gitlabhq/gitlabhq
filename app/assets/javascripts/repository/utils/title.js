const DEFAULT_TITLE = '· GitLab';
// eslint-disable-next-line import/prefer-default-export
export const setTitle = (pathMatch, ref, project) => {
  if (!pathMatch) {
    document.title = `${project} ${DEFAULT_TITLE}`;
    return;
  }

  const path = pathMatch.replace(/^\//, '');
  const isEmpty = path === '';

  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  document.title = `${isEmpty ? 'Files' : path} · ${ref} · ${project} ${DEFAULT_TITLE}`;
};
