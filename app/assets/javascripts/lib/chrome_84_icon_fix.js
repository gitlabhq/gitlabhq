import { debounce } from 'lodash';

/*
  Chrome and Edge 84 have a bug relating to icon sprite svgs
  https://bugs.chromium.org/p/chromium/issues/detail?id=1107442

  If the SVG is loaded, under certain circumstances the icons are not
  shown. We load our sprite icons with JS and add them to the body.
  Then we iterate over all the `use` elements and replace their reference
  to that svg which we added internally. In order to avoid id conflicts,
  those are renamed with a unique prefix.

  We do that once the DOMContentLoaded fired and otherwise we use a
  mutation observer to re-trigger this logic.

  In order to not have a big impact on performance or to cause flickering
  of of content,

  1. we only do it for each svg once
  2. we debounce the event handler and just do it in a requestIdleCallback

  Before we tried to do it with the library svg4everybody and it had a big
  performance impact. See:
  https://gitlab.com/gitlab-org/quality/performance/-/issues/312
 */
document.addEventListener('DOMContentLoaded', async () => {
  const GITLAB_SVG_PREFIX = 'chrome-issue-230433-gitlab-svgs';
  const FILE_ICON_PREFIX = 'chrome-issue-230433-file-icons';
  const SKIP_ATTRIBUTE = 'data-replaced-by-chrome-issue-230433';

  const fixSVGs = () => {
    requestIdleCallback(() => {
      document.querySelectorAll(`use:not([${SKIP_ATTRIBUTE}])`).forEach(use => {
        const href = use?.getAttribute('href') ?? use?.getAttribute('xlink:href') ?? '';

        if (href.includes(window.gon.sprite_icons)) {
          use.removeAttribute('xlink:href');
          use.setAttribute('href', `#${GITLAB_SVG_PREFIX}-${href.split('#')[1]}`);
        } else if (href.includes(window.gon.sprite_file_icons)) {
          use.removeAttribute('xlink:href');
          use.setAttribute('href', `#${FILE_ICON_PREFIX}-${href.split('#')[1]}`);
        }

        use.setAttribute(SKIP_ATTRIBUTE, 'true');
      });
    });
  };

  const watchForNewSVGs = () => {
    const observer = new MutationObserver(debounce(fixSVGs, 200));
    observer.observe(document.querySelector('body'), {
      childList: true,
      attributes: false,
      subtree: true,
    });
  };

  const retrieveIconSprites = async (url, prefix) => {
    const div = document.createElement('div');
    div.classList.add('hidden');
    const result = await fetch(url);
    div.innerHTML = await result.text();
    div.querySelectorAll('[id]').forEach(node => {
      node.setAttribute('id', `${prefix}-${node.getAttribute('id')}`);
    });
    document.body.append(div);
  };

  if (window.gon && window.gon.sprite_icons) {
    await retrieveIconSprites(window.gon.sprite_icons, GITLAB_SVG_PREFIX);
    if (window.gon.sprite_file_icons) {
      await retrieveIconSprites(window.gon.sprite_file_icons, FILE_ICON_PREFIX);
    }

    fixSVGs();
    watchForNewSVGs();
  }
});
