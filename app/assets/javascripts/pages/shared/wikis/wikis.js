import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import Tracking from '~/tracking';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsWiki from '~/behaviors/shortcuts/shortcuts_wiki';

const TRACKING_EVENT_NAME = 'view_wiki_page';
const TRACKING_CONTEXT_SCHEMA = 'iglu:com.gitlab/wiki_page_context/jsonschema/1-0-1';

export default class Wikis {
  constructor() {
    this.sidebarEl = document.querySelector('.js-wiki-sidebar');
    this.sidebarExpanded = false;

    const sidebarToggles = document.querySelectorAll('.js-sidebar-wiki-toggle');
    for (let i = 0; i < sidebarToggles.length; i += 1) {
      sidebarToggles[i].addEventListener('click', (e) => this.handleToggleSidebar(e));
    }

    const listToggles = document.querySelectorAll('.js-wiki-list-toggle');

    listToggles.forEach((listToggle) => {
      listToggle.querySelector('.js-wiki-list-expand-button')?.addEventListener('click', () => {
        listToggle.classList.remove('collapsed');
      });
      listToggle.querySelector('.js-wiki-list-collapse-button')?.addEventListener('click', () => {
        listToggle.classList.add('collapsed');
      });
    });

    window.addEventListener('resize', () => this.renderSidebar());
    this.renderSidebar();

    Wikis.trackPageView();
    Wikis.initShortcuts();
  }

  handleToggleSidebar(e) {
    e.preventDefault();
    this.sidebarExpanded = !this.sidebarExpanded;
    this.renderSidebar();
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
        classList.remove('right-sidebar-collapsed');
        classList.add('right-sidebar-expanded');
      }
    } else if (classList.contains('right-sidebar-expanded')) {
      classList.add('right-sidebar-collapsed');
      classList.remove('right-sidebar-expanded');
    }
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
