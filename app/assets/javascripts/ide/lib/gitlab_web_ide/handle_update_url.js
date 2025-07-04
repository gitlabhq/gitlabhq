import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';

function getWebIdeUrl(projectPath, branchName) {
  return webIDEUrl(joinPaths('/', projectPath, 'edit', branchName, '-/'));
}

export const handleUpdateUrl = ({ projectPath, ref }) => {
  const newUrl = getWebIdeUrl(projectPath, ref);

  window.history.replaceState(null, '', newUrl);
  window.location.reload();
};
