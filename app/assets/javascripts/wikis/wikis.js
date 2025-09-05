import { GlBreakpointInstance as bp } from '@gitlab/ui/src/utils';
import Tracking from '~/tracking';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsWiki from '~/behaviors/shortcuts/shortcuts_wiki';

const TRACKING_EVENT_NAME = 'view_wiki_page';
const TRACKING_CONTEXT_SCHEMA = 'iglu:com.gitlab/wiki_page_context/jsonschema/1-0-1';

export default class Wikis {
  constructor() {
    this.wikiPageHeaderEl = document.querySelector('.js-wiki-page-header');
    this.sidebarEl = document.querySelector('.js-wiki-sidebar');
    this.sidebarExpanded = false;

    document
      .querySelector('.js-sidebar-wiki-toggle')
      .addEventListener('click', this.handleToggleSidebar.bind(this));

    // Store pages visbility in localStorage
    const pagesToggle = document.querySelector('.js-wiki-expand-pages-list');
    if (pagesToggle) {
      if (localStorage.getItem('wiki-sidebar-expanded') === 'expanded') {
        pagesToggle.classList.remove('collapsed');
      }
      pagesToggle.addEventListener('click', (e) => {
        pagesToggle.classList.toggle('collapsed');

        if (!pagesToggle.classList.contains('collapsed')) {
          localStorage.setItem('wiki-sidebar-expanded', 'expanded');
        } else {
          localStorage.removeItem('wiki-sidebar-expanded');
        }

        e.stopImmediatePropagation();
      });
    }

    const listToggles = document.querySelectorAll('.js-wiki-list-toggle');
    listToggles.forEach((listToggle) => {
      listToggle.querySelectorAll('a').forEach((link) => {
        link.addEventListener('click', (e) => e.stopPropagation());
      });

      listToggle.addEventListener('click', (e) => {
        listToggle.classList.toggle('collapsed');

        e.stopImmediatePropagation();
      });
    });

    window.addEventListener('resize', () => this.renderSidebar());
    this.renderSidebar();

    Wikis.trackPageView();
    Wikis.initShortcuts();
  }

  handleToggleSidebar(e) {
    e.preventDefault();
    const isSidebarExpanded = this.sidebarEl.classList.contains('right-sidebar-expanded');
    this.sidebarExpanded = !isSidebarExpanded;

    if (isSidebarExpanded) {
      this.collapseSidebar();
    } else {
      this.expandSidebar();
    }
  }

  static sidebarCanCollapse() {
    const bootstrapBreakpoint = bp.getBreakpointSize();
    return bootstrapBreakpoint === 'xs' || bootstrapBreakpoint === 'sm';
  }

  renderSidebar() {
    if (!this.sidebarEl) return;
    const { classList } = this.sidebarEl;
    if (this.sidebarExpanded || !Wikis.sidebarCanCollapse()) {
      if (!classList.contains('right-sidebar-expanded')) {
        this.expandSidebar();
      }
    } else if (classList.contains('right-sidebar-expanded')) {
      this.collapseSidebar();
    }
  }

  collapseSidebar() {
    if (!this.sidebarEl) return;

    const { classList } = this.sidebarEl;
    classList.add('right-sidebar-collapsed');
    classList.remove('right-sidebar-expanded');
  }

  expandSidebar() {
    if (!this.sidebarEl) return;

    const { classList } = this.sidebarEl;
    classList.remove('right-sidebar-collapsed');
    classList.add('right-sidebar-expanded');
  }

  static trackPageView() {
    const wikiPageContent = document.querySelector('.js-wiki-page-content[data-tracking-context]');
    if (!wikiPageContent) return;

    Tracking.event(document.body.dataset.page, TRACKING_EVENT_NAME, {
      label: TRACKING_EVENT_NAME,
      context: {
        schema: TRACKING_CONTEXT_SCHEMA,
        data: JSON.parse(wikiPageContent.dataset.trackingContext),
      },
    });
  }

  static initShortcuts() {
    addShortcutsExtension(ShortcutsWiki);
  }
}
