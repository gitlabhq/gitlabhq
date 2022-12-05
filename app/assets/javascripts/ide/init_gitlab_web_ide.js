import { start } from '@gitlab/web-ide';
import { getBaseConfig } from './lib/gitlab_web_ide/get_base_config';
import { setupRootElement } from './lib/gitlab_web_ide/setup_root_element';

export const initGitlabWebIDE = async (el) => {
  // what: Pull what we need from the element. We will replace it soon.
  const { cspNonce: nonce, branchName: ref, projectPath } = el.dataset;

  const rootEl = setupRootElement(el);

  start(rootEl, {
    ...getBaseConfig(),
    nonce,
    projectPath,
    ref,
  });
};
