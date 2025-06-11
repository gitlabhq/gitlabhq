import { GlTable, GlFormInput } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import JSONTable from '~/behaviors/components/json_table.vue';

const TEST_FIELDS = [
  'A',
  {
    key: 'B',
    label: 'Second',
    sortable: true,
    other: 'foo',
    class: 'someClass',
  },
  {
    key: 'C',
    label: 'Third',
  },
  'D',
];
const TEST_ITEMS = [
  { A: 1, B: 'lorem', C: 2, D: null, E: 'dne' },
  { A: 2, B: 'ipsum', C: 2, D: null, E: 'dne' },
  { A: 3, B: 'dolar', C: 2, D: null, E: 'dne' },
];

describe('behaviors/components/json_table', () => {
  let wrapper;

  const buildWrapper = ({
    fields = ['A'],
    items = [{ A: 'Foo bar' }],
    filter = undefined,
    caption = undefined,
    isHtmlSafe = false,
  } = {}) => {
    wrapper = mountExtended(JSONTable, {
      propsData: {
        fields,
        items,
        hasFilter: filter,
        caption,
        isHtmlSafe,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findFilterInput = () => wrapper.findComponent(GlFormInput);

  describe('default', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders a GLTable', () => {
      expect(findTable().props()).toMatchObject({ fields: ['A'] });
      expect(findTable().html()).toContain('Foo bar');
    });

    it('does not render filter input', () => {
      expect(findFilterInput().exists()).toBe(false);
    });

    it('renders caption', () => {
      expect(findTable().text()).toContain('Generated with JSON data');
    });
  });

  describe('with filter', () => {
    beforeEach(() => {
      buildWrapper({
        filter: true,
      });
    });

    it('renders filter input', () => {
      expect(findFilterInput().props()).toMatchObject({
        value: '',
        placeholder: 'Type to search',
      });
    });

    it('when input is changed, updates table filter', async () => {
      await findFilterInput().vm.$emit('input', 'New value!');

      expect(findFilterInput().props()).toMatchObject({
        placeholder: 'Type to search',
        value: 'New value!',
      });
    });
  });

  describe('with multiple fields', () => {
    beforeEach(() => {
      buildWrapper({
        fields: TEST_FIELDS,
        items: TEST_ITEMS,
      });
    });

    it('passes cleaned fields and items to table', () => {
      expect(findTable().props()).toMatchObject({
        fields: [
          'A',
          {
            key: 'B',
            label: 'Second',
            sortable: true,
            class: 'someClass',
          },
          {
            key: 'C',
            label: 'Third',
            sortable: false,
            class: [],
          },
          'D',
        ],
      });

      const html = findTable().html();

      expect(html).toContain('lorem');
      expect(html).toContain('ipsum');
      expect(html).toContain('dolar');
    });
  });

  describe('with HTML content', () => {
    beforeEach(() => {
      buildWrapper({
        fields: ['AB'],
        items: [
          { AB: '<div class="malicious-class" style="position:fixed;">Cell</div>' },
          { AB: '<div class="malicious-class" style="position:fixed;">Cell</div>' },
        ],
        isHtmlSafe: true,
        caption: `loading ... <i class="js-toggle-container"><i class='js-toggle-lazy-diff file-holder diff-content' style='position:fixed;top:0px;left:0px;right:0px;bottom:0px' data-lines-path='https://gitlab.com/-/snippets/4789748/raw/main/alert.json'> <table><tbody></tbody></table></i>`,
      });
    });

    it('sanitizes caption and cell HTML by removing class and style attributes', () => {
      const tableHtml = findTable().html();

      expect(tableHtml).toContain('loading');
      expect(tableHtml).toContain('Cell');

      expect(tableHtml).not.toContain('i class=');
      expect(tableHtml).not.toContain('style=');
      expect(tableHtml).not.toContain('class="malicious-class"');
      expect(tableHtml).not.toContain('style="position:fixed;"');
    });
  });
});
