import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import WikiMoreDropdown from '~/pages/shared/wikis/components/wiki_more_dropdown.vue';
import DeleteWikiModal from '~/pages/shared/wikis/components/delete_wiki_modal.vue';
import printMarkdownDom from '~/lib/print_markdown_dom';
import { mockLocation, restoreLocation } from '../test_utils';

jest.mock('~/lib/print_markdown_dom');

describe('pages/shared/wikis/components/wiki_more_dropdown', () => {
  let wrapper;

  const createComponent = (provide) => {
    wrapper = shallowMountExtended(WikiMoreDropdown, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      provide: {
        newUrl: 'https://new.url/path',
        history: 'https://history.url/path',
        print: {
          target: '#content-body',
          title: 'test title',
          stylesheet: [],
        },
        pageTitle: 'Wiki title',
        csrfToken: '',
        deleteWikiUrl: 'https://delete.url/path',
        cloneUrl: 'https://clone.url/path',
        cloneLinkClass: '',
        templatesUrl: 'https://templates.url/path',
        templatesLinkClass: '',
        pagePersisted: true,
        ...provide,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
        DeleteWikiModal,
      },
    });
  };

  const findMoreDropdown = () => wrapper.findByTestId('wiki-more-dropdown');
  const findMoreDropdownTooltip = () => getBinding(findMoreDropdown().element, 'gl-tooltip');
  const findNewItem = () => wrapper.findByTestId('page-new-button');
  const findHistoryItem = () => wrapper.findByTestId('page-history-button');
  const findPrintItem = () => wrapper.findByTestId('page-print-button');
  const findDeleteItem = () => wrapper.findByTestId('page-delete-button');
  const findTemplatesItem = () => wrapper.findByTestId('page-templates-button');
  const findCloneRepositoryItem = () => wrapper.findByTestId('page-clone-button');

  describe('new page', () => {
    it('shows label "New page"', () => {
      createComponent();

      expect(findNewItem().text()).toBe('New page');
    });

    it('renders if `newUrl` is set', () => {
      createComponent({ newUrl: false });

      expect(findNewItem().exists()).toBe(false);

      createComponent();

      expect(findNewItem().exists()).toBe(true);
    });

    it('should have new page url', () => {
      createComponent();

      expect(findNewItem().attributes('href')).toBe('https://new.url/path');
    });

    it('shows label "New template" on a template page', () => {
      mockLocation('http://gitlab.com/gitlab-org/gitlab/-/wikis/templates/abc');

      createComponent();

      expect(findNewItem().text()).toBe('New template');

      restoreLocation();
    });
  });

  describe('history', () => {
    it('shows label "Page history"', () => {
      createComponent();

      expect(findHistoryItem().text()).toBe('Page history');
    });

    it('shows label "Template history" when page is a template', () => {
      mockLocation('http://gitlab.com/gitlab-org/gitlab/-/wikis/templates/abc');

      createComponent();

      expect(findHistoryItem().text()).toBe('Template history');

      restoreLocation();
    });

    it('renders if `history` is set', () => {
      createComponent({ history: false });

      expect(findHistoryItem().exists()).toBe(false);

      createComponent();

      expect(findHistoryItem().exists()).toBe(true);
    });

    it('should have history page url', () => {
      createComponent();

      expect(findHistoryItem().attributes('href')).toBe('https://history.url/path');
    });
  });

  describe('print', () => {
    beforeEach(() => {
      document.body.innerHTML = '<div id="content-body">Content</div>';
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('renders if `print` is set', () => {
      createComponent({ print: false });

      expect(findPrintItem().exists()).toBe(false);

      createComponent();

      expect(findPrintItem().exists()).toBe(true);
    });

    it('should print the content', () => {
      createComponent();

      expect(findPrintItem().exists()).toBe(true);

      findPrintItem().trigger('click');

      expect(printMarkdownDom).toHaveBeenCalledWith({
        target: document.querySelector('#content-body'),
        title: 'test title',
        stylesheet: [],
      });
    });
  });

  describe('delete', () => {
    it('shows label "Delete page"', () => {
      createComponent();

      expect(findDeleteItem().text()).toBe('Delete page');
    });

    it('renders only if `pagePersisted` is set', () => {
      createComponent({ pagePersisted: false });

      expect(findDeleteItem().exists()).toBe(false);

      createComponent();

      expect(findDeleteItem().exists()).toBe(true);
    });
  });

  describe('templates', () => {
    it('shows label "Templates"', () => {
      createComponent();

      expect(findTemplatesItem().text()).toBe('Templates');
    });

    it('renders if `templatesUrl` is set', () => {
      createComponent({ templatesUrl: false });

      expect(findTemplatesItem().exists()).toBe(false);

      createComponent();

      expect(findTemplatesItem().exists()).toBe(true);
    });

    it('should have templates page url', () => {
      createComponent();

      expect(findTemplatesItem().attributes('href')).toBe('https://templates.url/path');
    });
  });

  describe('clone repository', () => {
    it('shows label "Clone repository"', () => {
      createComponent();

      expect(findCloneRepositoryItem().text()).toBe('Clone repository');
    });

    it('renders if `templatesUrl` is set', () => {
      createComponent({ cloneUrl: false });

      expect(findCloneRepositoryItem().exists()).toBe(false);

      createComponent();

      expect(findCloneRepositoryItem().exists()).toBe(true);
    });

    it('should have clone repository page url', () => {
      createComponent();

      expect(findCloneRepositoryItem().attributes('href')).toBe('https://clone.url/path');
    });
  });

  describe('More actions menu', () => {
    createComponent();

    it('renders the dropdown button', () => {
      createComponent();

      expect(findMoreDropdown().exists()).toBe(true);
    });

    it('renders tooltip', () => {
      createComponent();

      expect(findMoreDropdownTooltip().value).toBe('Wiki actions');
    });
  });
});
