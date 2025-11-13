import { ZERO_CHANGES_ALT_DISPLAY } from '../constants';

const endpointRE = /^(\/?(.+\/)+(.+)\/-\/merge_requests\/(\d+)).*$/i;
const SHA1RE = /([a-f0-9]{40})/g;

function getVersionInfo({ endpoint } = {}) {
  const dummyRoot = 'https://gitlab.com';
  const endpointUrl = new URL(endpoint, dummyRoot);
  const params = Object.fromEntries(endpointUrl.searchParams.entries());

  const { start_sha: startSha, diff_id: diffId } = params;

  return {
    diffId,
    startSha,
  };
}

function findFirstText(el) {
  let txt;

  el.childNodes.forEach((node) => {
    if (node.nodeType === 3) {
      if (!txt) {
        txt = node;
      }
    } else {
      txt = findFirstText(node);
    }
  });

  return txt;
}

export function updateChangesTabCount({
  count,
  badge = document.querySelector('.js-diffs-tab .gl-badge'),
} = {}) {
  const setters = {
    // The purpose of this function is to assign to this parameter
    /* eslint-disable no-param-reassign */
    TEXT: (node, val) => {
      node.nodeValue = val;
    },
    ELEMENT: (node, val) => {
      node.textContent = val;
    },
    /* eslint-enable no-param-reassign */
  };

  if (badge) {
    const txt = findFirstText(badge);
    let el = badge;
    let setter;

    if (txt) {
      setter = setters.TEXT;
      el = txt;
    } else {
      setter = setters.ELEMENT;
    }

    setter(el, count || ZERO_CHANGES_ALT_DISPLAY);
  }
}

export function getDerivedMergeRequestInformation({ endpoint } = {}) {
  let mrPath;
  let namespace;
  let project;
  let id;
  let diffId;
  let startSha;
  const matches = endpointRE.exec(endpoint);

  if (matches) {
    [, mrPath, namespace, project, id] = matches;
    ({ diffId, startSha } = getVersionInfo({ endpoint }));

    namespace = namespace.replace(/\/$/, '');
  }

  return {
    mrPath,
    namespace,
    project,
    id,
    diffId,
    startSha,
  };
}

export function extractFileHash({ input = '' } = {}) {
  const matches = input.match(SHA1RE);

  return matches?.[0];
}
