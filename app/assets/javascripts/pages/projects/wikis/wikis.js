import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { s__, sprintf } from '~/locale';

export default class Wikis {
  constructor() {
    this.sidebarEl = document.querySelector('.js-wiki-sidebar');
    this.sidebarExpanded = false;

    const sidebarToggles = document.querySelectorAll('.js-sidebar-wiki-toggle');
    for (let i = 0; i < sidebarToggles.length; i += 1) {
      sidebarToggles[i].addEventListener('click', e => this.handleToggleSidebar(e));
    }

    this.isNewWikiPage = Boolean(document.querySelector('.js-new-wiki-page'));
    this.editTitleInput = document.querySelector('form.wiki-form #wiki_title');
    this.commitMessageInput = document.querySelector('form.wiki-form #wiki_message');
    this.commitMessageI18n = this.isNewWikiPage
      ? s__('WikiPageCreate|Create %{pageTitle}')
      : s__('WikiPageEdit|Update %{pageTitle}');

    if (this.editTitleInput) {
      // Initialize the commit message on load
      if (this.editTitleInput.value) this.setWikiCommitMessage(this.editTitleInput.value);

      // Set the commit message as the page title is changed
      this.editTitleInput.addEventListener('keyup', e => this.handleWikiTitleChange(e));
    }

    window.addEventListener('resize', () => this.renderSidebar());
    this.renderSidebar();
  }

  handleWikiTitleChange(e) {
    this.setWikiCommitMessage(e.target.value);
  }

  setWikiCommitMessage(rawTitle) {
    let title = rawTitle;

    // Replace hyphens with spaces
    if (title) title = title.replace(/-+/g, ' ');

    const newCommitMessage = sprintf(this.commitMessageI18n, { pageTitle: title });
    this.commitMessageInput.value = newCommitMessage;
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
}
