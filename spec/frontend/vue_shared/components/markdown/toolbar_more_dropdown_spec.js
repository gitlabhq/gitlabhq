import { nextTick } from 'vue';
import { GlDisclosureDropdown, GlTooltip } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Tracking from '~/tracking';
import ToolbarMoreDropdown from '~/vue_shared/components/markdown/toolbar_more_dropdown.vue';
import { updateText } from '~/lib/utils/text_markdown';
import { formatMarkdownTable } from '~/lib/utils/markdown_table_cleanup';

jest.mock('~/tracking');
jest.mock('~/lib/utils/text_markdown');
jest.mock('~/lib/utils/markdown_table_cleanup');
jest.mock('~/content_editor/extensions/code_block_highlight', () => ({
  DEFAULT_GLQL_VIEW_CONTENT:
    'query: assignee = currentUser()\nfields: title, createdAt, milestone, assignee\ntitle: Issues assigned to current user',
}));
jest.mock('~/content_editor/extensions/diagram', () => ({
  DEFAULT_MERMAID_CONTENT: 'graph TD;\n    A-->B;\n    A-->C;\n    B-->D;\n    C-->D;',
  DEFAULT_PLANTUML_CONTENT:
    '@startuml\nAlice -> Bob: Authentication Request\nBob --> Alice: Authentication Response\n@enduml',
}));

describe('ToolbarMoreDropdown', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = mountExtended(ToolbarMoreDropdown);
  };
  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlTooltip = () => wrapper.findComponent(GlTooltip);
  beforeEach(() => {
    createWrapper();
  });

  it('renders the dropdown with correct props', () => {
    expect(findGlDisclosureDropdown().props()).toMatchObject({
      size: 'small',
      category: 'tertiary',
      icon: 'plus',
      toggleText: 'More options',
      textSrOnly: true,
    });
  });

  it('renders tooltip', () => {
    expect(findGlTooltip().text()).toBe('More options');
    expect(findGlTooltip().props('placement')).toBe('top');
  });

  it('hides tooltip when dropdown is open', async () => {
    expect(findGlTooltip().text()).toBe('More options');

    findGlDisclosureDropdown().vm.$emit('shown');

    await nextTick();

    expect(findGlTooltip().exists()).toBe(false);
  });

  describe.each`
    name                     | expectedMarkdown                                                                                                                          | trackingProperty
    ${'Alert'}               | ${'> [!NOTE]\n> {text}'}                                                                                                                  | ${'alert'}
    ${'Code block'}          | ${'```\n{text}\n```'}                                                                                                                     | ${'codeBlock'}
    ${'Collapsible section'} | ${'<details>\n<summary>Click to expand</summary>\n\n{text}\n\n</details>'}                                                                | ${'details'}
    ${'Bullet list'}         | ${'- {text}'}                                                                                                                             | ${'bulletList'}
    ${'Ordered list'}        | ${'1. {text}'}                                                                                                                            | ${'orderedList'}
    ${'Task list'}           | ${'- [ ] {text}'}                                                                                                                         | ${'taskList'}
    ${'Horizontal rule'}     | ${'\n---\n'}                                                                                                                              | ${'horizontalRule'}
    ${'Embedded view New'}   | ${'```glql\nquery: assignee = currentUser()\nfields: title, createdAt, milestone, assignee\ntitle: Issues assigned to current user\n```'} | ${'glqlView'}
    ${'Mermaid diagram'}     | ${'```mermaid\ngraph TD;\n    A-->B;\n    A-->C;\n    B-->D;\n    C-->D;\n```'}                                                           | ${'diagram'}
    ${'PlantUML diagram'}    | ${'```plantuml\n@startuml\nAlice -> Bob: Authentication Request\nBob --> Alice: Authentication Response\n@enduml\n```'}                   | ${'diagram'}
    ${'Table of contents'}   | ${'[[_TOC_]]'}                                                                                                                            | ${'tableOfContents'}
  `('when $name option is clicked', ({ name, expectedMarkdown, trackingProperty }) => {
    let mockTextArea;

    beforeEach(() => {
      mockTextArea = document.createElement('textarea');
      document.body.innerHTML = '<div class="md-area"></div>';
      document.querySelector('.md-area').appendChild(mockTextArea);

      // Mock the DOM traversal
      jest.spyOn(wrapper.vm.$el, 'closest').mockReturnValue(document.querySelector('.md-area'));
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it(`inserts correct markdown for ${name}`, async () => {
      const btn = wrapper.findByRole('button', { name });

      await btn.trigger('click');

      expect(updateText).toHaveBeenCalledWith({
        textArea: mockTextArea,
        tag: expectedMarkdown,
        cursorOffset: 0,
        wrap: false,
      });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'execute_toolbar_control', {
        label: 'markdown_editor',
        property: trackingProperty,
      });
    });
  });

  describe('when Reformat table option is clicked', () => {
    let mockTextArea;

    beforeEach(() => {
      mockTextArea = document.createElement('textarea');
      document.body.innerHTML = '<div class="md-area"></div>';
      document.querySelector('.md-area').appendChild(mockTextArea);

      // Mock the DOM traversal
      jest.spyOn(wrapper.vm.$el, 'closest').mockReturnValue(document.querySelector('.md-area'));
    });

    afterEach(() => {
      document.body.innerHTML = '';
      jest.clearAllMocks();
    });

    it('reformats a simple table', async () => {
      const unformattedTable = '| Col 1 | Col 2 |\n|---- |---- |\n| first column | second column |';
      const formattedTable =
        '| Col 1        | Col 2         |\n|--------------|---------------|\n| first column | second column |\n';

      // Set up textarea with unformatted table text selected
      mockTextArea.value = unformattedTable;
      mockTextArea.selectionStart = 0;
      mockTextArea.selectionEnd = unformattedTable.length;

      // Mock formatMarkdownTable to return formatted table
      formatMarkdownTable.mockReturnValue(formattedTable);

      const btn = wrapper.findByRole('button', { name: 'Reformat table' });

      await btn.trigger('click');

      expect(formatMarkdownTable).toHaveBeenCalledWith(unformattedTable);
      expect(updateText).toHaveBeenCalledWith({
        textArea: mockTextArea,
        tag: formattedTable,
        cursorOffset: 0,
        wrap: false,
        replaceText: true,
      });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'execute_toolbar_control', {
        label: 'markdown_editor',
        property: 'reformatTable',
      });
    });

    it('handles empty selection gracefully', async () => {
      // Set up textarea with no selection
      mockTextArea.value = 'Some text with no table';
      mockTextArea.selectionStart = 5;
      mockTextArea.selectionEnd = 5;

      // Mock formatMarkdownTable to return empty string for non-table content
      formatMarkdownTable.mockReturnValue('');

      const btn = wrapper.findByRole('button', { name: 'Reformat table' });

      await btn.trigger('click');

      expect(formatMarkdownTable).toHaveBeenCalledWith('');
      expect(updateText).toHaveBeenCalledWith({
        textArea: mockTextArea,
        tag: '',
        cursorOffset: 0,
        wrap: false,
        replaceText: true,
      });
    });

    it('handles partial table selection', async () => {
      const fullText = 'Some text\n| Col 1 | Col 2 |\n|---- |---- |\n| data1 | data2 |\nMore text';
      const selectedTable = '| Col 1 | Col 2 |\n|---- |---- |\n| data1 | data2 |';
      const formattedTable = '| Col 1 | Col 2 |\n|-------|-------|\n| data1 | data2 |\n';

      // Set up textarea with partial table selection
      mockTextArea.value = fullText;
      mockTextArea.selectionStart = 10; // Start of table
      mockTextArea.selectionEnd = 10 + selectedTable.length; // End of table

      // Mock formatMarkdownTable to return formatted table
      formatMarkdownTable.mockReturnValue(formattedTable);

      const btn = wrapper.findByRole('button', { name: 'Reformat table' });

      await btn.trigger('click');

      expect(formatMarkdownTable).toHaveBeenCalledWith(selectedTable);
      expect(updateText).toHaveBeenCalledWith({
        textArea: mockTextArea,
        tag: formattedTable,
        cursorOffset: 0,
        wrap: false,
        replaceText: true,
      });
    });
  });

  describe('getCurrentTextArea', () => {
    it('handles missing textarea gracefully', () => {
      jest.spyOn(wrapper.vm.$el, 'closest').mockReturnValue(null);

      expect(() => wrapper.vm.insertMarkdown('test')).not.toThrow();
      expect(updateText).not.toHaveBeenCalled();
    });
  });

  it('shows a "New" badge for the embedded view option', () => {
    const embeddedViewItem = findGlDisclosureDropdown()
      .props()
      .items.find((item) => item.text === 'Embedded view');

    expect(embeddedViewItem.badge).toMatchObject({
      text: 'New',
      variant: 'info',
      size: 'small',
      target: '_blank',
      href: '/help/user/glql/_index',
    });
  });
});
