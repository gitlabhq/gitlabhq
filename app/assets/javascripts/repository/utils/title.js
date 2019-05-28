// eslint-disable-next-line import/prefer-default-export
export const setTitle = (pathMatch, ref, project) => {
  const path = pathMatch.replace(/^\//, '');
  const isEmpty = path === '';

  document.title = `${isEmpty ? 'Files' : path} · ${ref} · ${project}`;
};
