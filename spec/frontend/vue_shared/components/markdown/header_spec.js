import $ from 'jquery';
import { nextTick } from 'vue';
import { GlTabs } from '@gitlab/ui';
import HeaderComponent from '~/vue_shared/components/markdown/header.vue';
import ToolbarButton from '~/vue_shared/components/markdown/toolbar_button.vue';
import DrawioToolbarButton from '~/vue_shared/components/markdown/drawio_toolbar_button.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Markdown field header component', () => {
  let wrapper;

  const createWrapper = (props) => {
    wrapper = shallowMountExtended(HeaderComponent, {
      propsData: {
        previewMarkdown: false,
        ...props,
      },
      stubs: { GlTabs },
    });
  };

  const findWriteTab = () => wrapper.findByTestId('write-tab');
  const findPreviewTab = () => wrapper.findByTestId('preview-tab');
  const findToolbar = () => wrapper.findByTestId('md-header-toolbar');
  const findToolbarButtons = () => wrapper.findAllComponents(ToolbarButton);
  const findToolbarButtonByProp = (prop, value) =>
    findToolbarButtons()
      .filter((button) => button.props(prop) === value)
      .at(0);
  const findDrawioToolbarButton = () => wrapper.findComponent(DrawioToolbarButton);

  beforeEach(() => {
    window.gl = {
      client: {
        isMac: true,
      },
    };

    createWrapper();
  });

  describe('markdown header buttons', () => {
    it('renders the buttons with the correct title', () => {
      const buttons = [
        'Insert suggestion',
        'Add bold text (⌘B)',
        'Add italic text (⌘I)',
        'Add strikethrough text (⌘⇧X)',
        'Insert a quote',
        'Insert code',
        'Add a link (⌘K)',
        'Add a bullet list',
        'Add a numbered list',
        'Add a checklist',
        'Indent line (⌘])',
        'Outdent line (⌘[)',
        'Add a collapsible section',
        'Add a table',
        'Go full screen',
      ];
      const elements = findToolbarButtons();

      elements.wrappers.forEach((buttonEl, index) => {
        expect(buttonEl.props('buttonTitle')).toBe(buttons[index]);
      });
    });

    it('renders "Attach a file or image" button using gl-button', () => {
      const button = wrapper.findByTestId('button-attach-file');

      expect(button.element.tagName).toBe('GL-BUTTON-STUB');
      expect(button.attributes('title')).toBe('Attach a file or image');
    });

    describe('when the user is on a non-Mac', () => {
      beforeEach(() => {
        delete window.gl.client.isMac;

        createWrapper();
      });

      it('renders keyboard shortcuts with Ctrl+ instead of ⌘', () => {
        const boldButton = findToolbarButtonByProp('icon', 'bold');

        expect(boldButton.props('buttonTitle')).toBe('Add bold text (Ctrl+B)');
      });
    });
  });

  it('activates `write` tab when previewMarkdown is false', () => {
    expect(findWriteTab().attributes('active')).toBe('true');
    expect(findPreviewTab().attributes('active')).toBeUndefined();
  });

  it('activates `preview` tab when previewMarkdown is true', () => {
    createWrapper({ previewMarkdown: true });

    expect(findWriteTab().attributes('active')).toBeUndefined();
    expect(findPreviewTab().attributes('active')).toBe('true');
  });

  it('hides toolbar in preview mode', () => {
    createWrapper({ previewMarkdown: true });

    expect(findToolbar().classes().includes('gl-display-none!')).toBe(true);
  });

  it('emits toggle markdown event when clicking preview tab', async () => {
    const eventData = { target: {} };
    findPreviewTab().vm.$emit('click', eventData);

    await nextTick();
    expect(wrapper.emitted('preview-markdown').length).toEqual(1);

    findWriteTab().vm.$emit('click', eventData);

    await nextTick();
    expect(wrapper.emitted('write-markdown').length).toEqual(1);
  });

  it('does not emit toggle markdown event when triggered from another form', () => {
    $(document).triggerHandler('markdown-preview:show', [
      $(
        '<form><div class="js-vue-markdown-field"><textarea class="markdown-area"></textarea></div></form>',
      ),
    ]);

    expect(wrapper.emitted('preview-markdown')).toBeUndefined();
    expect(wrapper.emitted('write-markdown')).toBeUndefined();
  });

  it('blurs preview link after click', () => {
    const target = { blur: jest.fn() };
    findPreviewTab().vm.$emit('click', { target });

    expect(target.blur).toHaveBeenCalled();
  });

  it('renders markdown table template', () => {
    const tableButton = findToolbarButtonByProp('icon', 'table');

    expect(tableButton.props('tag')).toEqual(
      '| header | header |\n| ------ | ------ |\n|        |        |\n|        |        |',
    );
  });

  it('renders suggestion template', () => {
    expect(findToolbarButtonByProp('buttonTitle', 'Insert suggestion').props('tag')).toEqual(
      '```suggestion:-0+0\n{text}\n```',
    );
  });

  it('renders collapsible section template', () => {
    const detailsBlockButton = findToolbarButtonByProp('icon', 'details-block');

    expect(detailsBlockButton.props('tag')).toEqual(
      '<details><summary>Click to expand</summary>\n{text}\n</details>',
    );
  });

  it('does not render suggestion button if `canSuggest` is set to false', () => {
    createWrapper({
      canSuggest: false,
    });

    expect(wrapper.find('.js-suggestion-btn').exists()).toBe(false);
  });

  it('hides preview tab when previewMarkdown property is false', () => {
    createWrapper({
      enablePreview: false,
    });

    expect(wrapper.findByTestId('preview-tab').exists()).toBe(false);
  });

  describe('restricted tool bar items', () => {
    let defaultCount;

    beforeEach(() => {
      defaultCount = findToolbarButtons().length;
    });

    it('restricts items as per input', () => {
      createWrapper({
        restrictedToolBarItems: ['quote'],
      });

      expect(findToolbarButtons().length).toBe(defaultCount - 1);
    });

    it('shows all items by default', () => {
      createWrapper();

      expect(findToolbarButtons().length).toBe(defaultCount);
    });
  });

  describe('when drawIOEnabled is true', () => {
    const uploadsPath = '/uploads';
    const markdownPreviewPath = '/preview';

    beforeEach(() => {
      createWrapper({
        drawioEnabled: true,
        uploadsPath,
        markdownPreviewPath,
      });
    });

    it('renders drawio toolbar button', () => {
      expect(findDrawioToolbarButton().props()).toEqual({
        uploadsPath,
        markdownPreviewPath,
      });
    });
  });
});
