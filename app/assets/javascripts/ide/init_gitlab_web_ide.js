import { cleanTrailingSlash } from './stores/utils';

export const initGitlabWebIDE = async (el) => {
  const { start } = await import('@gitlab/web-ide');

  const { gitlab_url: gitlabUrl } = window.gon;
  const baseUrl = new URL(process.env.GITLAB_WEB_IDE_PUBLIC_PATH, window.location.origin);

  // what: Pull what we need from the element. We will replace it soon.
  const { cspNonce: nonce, branchName: ref, projectPath } = el.dataset;

  // what: Clean up the element, but preserve id.
  // why:  This way we don't inherit any `ide-loading` side-effects. This
  //       mirrors the behavior of Vue when it mounts to an element.
  const newEl = document.createElement(el.tagName);
  newEl.id = el.id;
  newEl.classList.add('gl--flex-center', 'gl-relative', 'gl-h-full');

  el.replaceWith(newEl);

  // what: Trigger start on our new mounting element
  await start(newEl, {
    baseUrl: cleanTrailingSlash(baseUrl.href),
    projectPath,
    gitlabUrl,
    ref,
    nonce,
  });
};
