import bp from '../../../breakpoints';
import { slugify } from '../../../lib/utils/text_utility';
import { parseQueryStringIntoObject } from '../../../lib/utils/common_utils';
import { mergeUrlParams, redirectTo } from '../../../lib/utils/url_utility';

export default class Wikis {
  constructor() {
    this.sidebarEl = document.querySelector('.js-wiki-sidebar');
    this.sidebarExpanded = false;

    const sidebarToggles = document.querySelectorAll('.js-sidebar-wiki-toggle');
    for (let i = 0; i < sidebarToggles.length; i += 1) {
      sidebarToggles[i].addEventListener('click', e => this.handleToggleSidebar(e));
    }

    this.newWikiForm = document.querySelector('form.new-wiki-page');
    if (this.newWikiForm) {
      this.newWikiForm.addEventListener('submit', e => this.handleNewWikiSubmit(e));
    }

    window.addEventListener('resize', () => this.renderSidebar());
    this.renderSidebar();
  }

  handleNewWikiSubmit(e) {
    if (!this.newWikiForm) return;

    const slugInput = this.newWikiForm.querySelector('#new_wiki_path');
    const slug = slugify(slugInput.value);

    if (slug.length > 0) {
      const wikisPath = slugInput.getAttribute('data-wikis-path');

      // If the wiki is empty, we need to merge the current URL params to keep the "create" view.
      const params = parseQueryStringIntoObject(window.location.search.substr(1));
      const url = mergeUrlParams(params, `${wikisPath}/${slug}`);
      redirectTo(url);

      e.preventDefault();
    }
  }

  handleToggleSidebar(e) {
    e.preventDefault();
    this.sidebarExpanded = !this.sidebarExpanded;
    this.renderSidebar();
  }

  static sidebarCanCollapse() {
    const bootstrapBreakpoint = bp.getBreakpointSize();
    return bootstrapBreakpoint === 'xs';
  }

  renderSidebar() {
    if (!this.sidebarEl) return;
    const { classList } = this.sidebarEl;
    if (this.sidebarExpanded || !Wikis.sidebarCanCollapse()) {
      if (!classList.contains('right-sidebar-expanded')) {
        classList.remove('right-sidebar-collapsed');
        classList.add('right-sidebar-expanded');
      }
    } else if (classList.contains('right-sidebar-expanded')) {
      classList.add('right-sidebar-collapsed');
      classList.remove('right-sidebar-expanded');
    }
  }
}
