const DEFAULT_TITLE = '· GitLab';

export const setTitle = (pathMatch, ref, project) => {
  if (!pathMatch) {
    document.title = `${project} ${DEFAULT_TITLE}`;
    return;
  }

  const path = pathMatch.replace(/^\//, '');
  const isEmpty = path === '';

  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  document.title = `${isEmpty ? 'Files' : path} · ${ref} · ${project} ${DEFAULT_TITLE}`;
};

export function updateRefPortionOfTitle(sha, doc = document) {
  const { title = '' } = doc;
  const titleParts = title.split(' · ');

  if (titleParts.length > 1) {
    titleParts[1] = sha;

    /* eslint-disable-next-line no-param-reassign */
    doc.title = titleParts.join(' · ');
  }
}
