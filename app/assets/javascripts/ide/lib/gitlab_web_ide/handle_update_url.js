import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';

function withPrevious(fn) {
  let prev;

  return (arg) => {
    fn(arg, prev);
    prev = arg;
  };
}

function getWebIdeUrl(projectPath, branchName) {
  return webIDEUrl(joinPaths('/', projectPath, 'edit', branchName, '-/'));
}

export const handleUpdateUrl = withPrevious(({ projectPath, ref }, previous) => {
  if (!previous) {
    return;
  }

  if (previous.ref === ref) {
    return;
  }

  const newUrl = getWebIdeUrl(projectPath, ref);

  window.history.replaceState(null, '', newUrl);
});
