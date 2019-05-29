// eslint-disable-next-line import/prefer-default-export
export const setTitle = (pathMatch, ref, project) => {
  if (!pathMatch) return;

  const path = pathMatch.replace(/^\//, '');
  const isEmpty = path === '';

  document.title = `${isEmpty ? 'Files' : path} · ${ref} · ${project}`;
};
