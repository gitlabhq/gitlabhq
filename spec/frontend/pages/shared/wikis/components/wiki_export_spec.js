import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WikiExport from '~/pages/shared/wikis/components/wiki_export.vue';
import printMarkdownDom from '~/lib/print_markdown_dom';

jest.mock('~/lib/print_markdown_dom');

describe('pages/shared/wikis/components/wiki_export', () => {
  let wrapper;

  const createComponent = (provide) => {
    wrapper = shallowMount(WikiExport, {
      provide,
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findPrintItem = () =>
    findDropdown()
      .props('items')
      .find((x) => x.text === 'Print as PDF');

  describe('print', () => {
    beforeEach(() => {
      document.body.innerHTML = '<div id="content-body">Content</div>';
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('should print the content', () => {
      createComponent({
        target: '#content-body',
        title: 'test title',
        stylesheet: [],
      });

      findPrintItem().action();

      expect(printMarkdownDom).toHaveBeenCalledWith({
        target: document.querySelector('#content-body'),
        title: 'test title',
        stylesheet: [],
      });
    });
  });
});
