import $ from 'jquery';
import { nextTick } from 'vue';
import { GlToggle, GlButton } from '@gitlab/ui';
import HeaderComponent from '~/vue_shared/components/markdown/header.vue';
import CommentTemplatesDropdown from '~/vue_shared/components/markdown/comment_templates_dropdown.vue';
import ToolbarButton from '~/vue_shared/components/markdown/toolbar_button.vue';
import DrawioToolbarButton from '~/vue_shared/components/markdown/drawio_toolbar_button.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { updateText } from '~/lib/utils/text_markdown';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/text_markdown');

describe('Markdown field header component', () => {
  let wrapper;

  const createWrapper = ({ props = {}, provide = {}, attachTo = document.body } = {}) => {
    wrapper = shallowMountExtended(HeaderComponent, {
      attachTo,
      propsData: {
        previewMarkdown: false,
        ...props,
      },
      stubs: { GlToggle },
      provide,
    });
  };

  const findPreviewToggle = () => wrapper.findByTestId('preview-toggle');
  const findToolbar = () => wrapper.findByTestId('md-header-toolbar');
  const findToolbarButtons = () => wrapper.findAllComponents(ToolbarButton);
  const findToolbarButtonByProp = (prop, value) =>
    findToolbarButtons()
      .filter((button) => button.props(prop) === value)
      .at(0);
  const findDrawioToolbarButton = () => wrapper.findComponent(DrawioToolbarButton);
  const findCommentTemplatesDropdown = () => wrapper.findComponent(CommentTemplatesDropdown);

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

    it('renders correct title on non MacOS systems', () => {
      window.gl = {
        client: {
          isMac: false,
        },
      };

      createWrapper();

      const buttons = [
        'Insert suggestion',
        'Add bold text (Ctrl+B)',
        'Add italic text (Ctrl+I)',
        'Add strikethrough text (Ctrl+Shift+X)',
        'Insert a quote',
        'Insert code',
        'Add a link (Ctrl+K)',
        'Add a bullet list',
        'Add a numbered list',
        'Add a checklist',
        'Indent line (Ctrl+])',
        'Outdent line (Ctrl+[)',
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

  it('hides markdown preview when previewMarkdown is false', () => {
    expect(findPreviewToggle().text()).toBe('Preview');
  });

  it('shows markdown preview when previewMarkdown is true', () => {
    createWrapper({ props: { previewMarkdown: true } });

    expect(findPreviewToggle().text()).toBe('Continue editing');
  });

  it('hides toolbar in preview mode', () => {
    createWrapper({ props: { previewMarkdown: true } });

    // only one button is rendered in preview mode
    expect(findToolbar().findAllComponents(GlButton)).toHaveLength(1);
  });

  it('emits toggle markdown event when clicking preview toggle', async () => {
    findPreviewToggle().vm.$emit('click', true);

    await nextTick();
    expect(wrapper.emitted('showPreview').length).toEqual(1);

    findPreviewToggle().vm.$emit('click', false);

    await nextTick();
    expect(wrapper.emitted('showPreview').length).toEqual(2);
  });

  it('does not emit toggle markdown event when triggered from another form', () => {
    $(document).triggerHandler('markdown-preview:show', [
      $(
        '<form><div class="js-vue-markdown-field"><textarea class="markdown-area"></textarea></div></form>',
      ),
    ]);

    expect(wrapper.emitted('showPreview')).toBeUndefined();
    expect(wrapper.emitted('hidePreview')).toBeUndefined();
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
      props: {
        canSuggest: false,
      },
    });

    expect(wrapper.find('.js-suggestion-btn').exists()).toBe(false);
  });

  it('hides markdown preview when previewMarkdown property is false', () => {
    createWrapper({
      props: {
        enablePreview: false,
      },
    });

    expect(wrapper.findByTestId('preview-toggle').exists()).toBe(false);
  });

  describe('restricted tool bar items', () => {
    let defaultCount;

    beforeEach(() => {
      defaultCount = findToolbarButtons().length;
    });

    it('restricts items as per input', () => {
      createWrapper({
        props: {
          restrictedToolBarItems: ['quote'],
        },
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
        props: {
          drawioEnabled: true,
          uploadsPath,
          markdownPreviewPath,
        },
      });
    });

    it('renders drawio toolbar button', () => {
      expect(findDrawioToolbarButton().props()).toEqual({
        uploadsPath,
        markdownPreviewPath,
      });
    });
  });

  describe('when selecting a saved reply from the comment templates dropdown', () => {
    beforeEach(() => {
      setHTMLFixture('<div class="md-area"><textarea></textarea><div id="root"></div></div>');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('updates the textarea with the saved comment', async () => {
      createWrapper({
        attachTo: '#root',
        provide: {
          newCommentTemplatePath: 'some/path',
          glFeatures: {
            savedReplies: true,
          },
        },
      });

      await findCommentTemplatesDropdown().vm.$emit('select', 'Some saved comment');

      expect(updateText).toHaveBeenCalledWith({
        textArea: document.querySelector('textarea'),
        tag: 'Some saved comment',
        cursorOffset: 0,
        wrap: false,
      });
    });

    it('does not show the saved replies button if newCommentTemplatePath is not defined', () => {
      createWrapper({
        provide: {
          glFeatures: {
            savedReplies: true,
          },
        },
      });

      expect(findCommentTemplatesDropdown().exists()).toBe(false);
    });
  });
});
