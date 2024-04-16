import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import WikiMoreDropdown from '~/pages/shared/wikis/components/wiki_more_dropdown.vue';
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
        history: 'https://history.url/path',
        print: {
          target: '#content-body',
          title: 'test title',
          stylesheet: [],
        },
        ...provide,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  };

  const findMoreDropdown = () => wrapper.findByTestId('wiki-more-dropdown');
  const findMoreDropdownTooltip = () => getBinding(findMoreDropdown().element, 'gl-tooltip');
  const findHistoryItem = () => wrapper.findByTestId('page-history-button');
  const findPrintItem = () => wrapper.findByTestId('page-print-button');

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
