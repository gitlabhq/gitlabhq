import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { s__, sprintf } from '~/locale';

const MARKDOWN_LINK_TEXT = {
  markdown: '[Link Title](page-slug)',
  rdoc: '{Link title}[link:page-slug]',
  asciidoc: 'link:page-slug[Link title]',
  org: '[[page-slug]]',
};

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

    const changeFormatSelect = document.querySelector('#wiki_format');
    const linkExample = document.querySelector('.js-markup-link-example');

    if (changeFormatSelect) {
      changeFormatSelect.addEventListener('change', e => {
        linkExample.innerHTML = MARKDOWN_LINK_TEXT[e.target.value];
      });
    }

    const wikiTextarea = document.querySelector('form.wiki-form #wiki_content');
    const wikiForm = document.querySelector('form.wiki-form');

    if (wikiTextarea) {
      wikiTextarea.addEventListener('input', () => {
        window.onbeforeunload = () => '';
      });

      wikiForm.addEventListener('submit', () => {
        window.onbeforeunload = null;
      });
    }
  }

  handleWikiTitleChange(e) {
    this.setWikiCommitMessage(e.target.value);
  }

  setWikiCommitMessage(rawTitle) {
    let title = rawTitle;

    // Replace hyphens with spaces
    if (title) title = title.replace(/-+/g, ' ');

    const newCommitMessage = sprintf(this.commitMessageI18n, { pageTitle: title }, false);
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
