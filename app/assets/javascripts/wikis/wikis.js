import Tracking from '~/tracking';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsWiki from '~/behaviors/shortcuts/shortcuts_wiki';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';

const TRACKING_EVENT_NAME = 'view_wiki_page';
const TRACKING_CONTEXT_SCHEMA = 'iglu:com.gitlab/wiki_page_context/jsonschema/1-0-1';

export default class Wikis {
  constructor() {
    this.sidebarEl = document.querySelector('.js-wiki-sidebar');
    this.sidebarExpanded = false;

    document
      .querySelector('.js-sidebar-wiki-toggle-close')
      ?.addEventListener('click', this.collapseSidebar.bind(this));
    document
      .querySelector('.js-sidebar-wiki-toggle-open')
      ?.addEventListener('click', this.expandSidebar.bind(this));

    // Store pages visbility in localStorage
    const pagesToggle = document.querySelector('.js-wiki-expand-pages-list');
    if (pagesToggle) {
      if (localStorage.getItem('wiki-sidebar-expanded') === 'expanded') {
        pagesToggle.closest('.wiki-list').classList.remove('collapsed');
      }
      pagesToggle.addEventListener('click', (e) => {
        pagesToggle.closest('.wiki-list').classList.toggle('collapsed');

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

  loadSidebarState() {
    try {
      this.sidebarExpanded =
        JSON.parse(localStorage.getItem('wiki-sidebar-open')) ?? Wikis.sidebarExpandedByDefault();
    } catch {
      this.sidebarExpanded = Wikis.sidebarExpandedByDefault();
    }
  }

  static sidebarExpandedByDefault() {
    return PanelBreakpointInstance.getBreakpointSize() === 'xl';
  }

  renderSidebar() {
    if (!this.sidebarEl) return;
    const { classList } = this.sidebarEl;
    this.loadSidebarState();
    if (this.sidebarExpanded) {
      if (classList.contains('sidebar-collapsed')) {
        this.expandSidebar(false);
      }
    } else if (!classList.contains('sidebar-collapsed')) {
      this.collapseSidebar(false);
    }
    // Prevent transition animations from triggering right on page load
    setTimeout(() => {
      classList.add('transition-enabled');
    }, 100);
  }

  collapseSidebar(persistSetting = true) {
    if (!this.sidebarEl) return;

    const { classList } = this.sidebarEl;
    classList.add('sidebar-collapsed');
    classList.remove('sidebar-expanded');
    if (persistSetting) localStorage.setItem('wiki-sidebar-open', false);
  }

  expandSidebar(persistSetting = true) {
    if (!this.sidebarEl) return;

    const { classList } = this.sidebarEl;
    classList.remove('sidebar-collapsed');
    classList.add('sidebar-expanded');
    if (persistSetting) localStorage.setItem('wiki-sidebar-open', true);
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
