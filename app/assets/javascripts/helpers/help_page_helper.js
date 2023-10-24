import { joinPaths, setUrlFragment } from '~/lib/utils/url_utility';

const HELP_PAGE_URL_ROOT = '/help';

/**
 * Generate link to a GitLab documentation page.
 *
 * This is designed to mirror the Ruby `help_page_path` helper function, so that
 * the two can be used interchangeably.
 * @param {string} path - Path to doc file relative to the doc/ directory in the GitLab repository.
 *   Optionally, including `.md` or `.html` prefix
 * @param {object} [options]
 *   @param {string} [options.anchor] - Name of the anchor to scroll to on the documentation page.
 */
export const helpPagePath = (path, { anchor = '' } = {}) => {
  let helpPath = joinPaths(gon.relative_url_root || '/', HELP_PAGE_URL_ROOT, path);
  if (anchor) {
    helpPath = setUrlFragment(helpPath, anchor);
  }

  return helpPath;
};
