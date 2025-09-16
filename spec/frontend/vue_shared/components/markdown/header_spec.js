import $ from 'jquery';
import { nextTick } from 'vue';
import { GlToggle, GlButton } from '@gitlab/ui';
import { createWrapper as createVueTestWrapper } from '@vue/test-utils';
import HeaderComponent from '~/vue_shared/components/markdown/header.vue';
import HeaderDividerComponent from '~/vue_shared/components/markdown/header_divider.vue';
import CommentTemplatesModal from '~/vue_shared/components/markdown/comment_templates_modal.vue';
import ToolbarButton from '~/vue_shared/components/markdown/toolbar_button.vue';
import ToolbarTableButton from '~/content_editor/components/toolbar_table_button.vue';
import DrawioToolbarButton from '~/vue_shared/components/markdown/drawio_toolbar_button.vue';
import {
  mountExtended,
  shallowMountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
import { updateText } from '~/lib/utils/text_markdown';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/text_markdown', () => ({
  ...jest.requireActual('~/lib/utils/text_markdown'),
  updateText: jest.fn(),
}));

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
      provide: {
        glFeatures: {
          findAndReplace: true,
          ...provide?.glFeatures,
        },
        ...provide,
      },
    });
  };

  const findPreviewToggle = () => wrapper.findByTestId('preview-toggle');
  const findToolbar = () => wrapper.findByTestId('md-header-toolbar');
  const findToolbarButtons = () => wrapper.findAllComponents(ToolbarButton);
  const findDividers = () => wrapper.findAllComponents(HeaderDividerComponent);
  const findToolbarButtonByProp = (prop, value) =>
    findToolbarButtons()
      .filter((button) => button.props(prop) === value)
      .at(0);
  const findDrawioToolbarButton = () => wrapper.findComponent(DrawioToolbarButton);
  const findCommentTemplatesModal = () => wrapper.findComponent(CommentTemplatesModal);
  const findToolbarTableButton = () => wrapper.findComponent(ToolbarTableButton);

  beforeEach(() => {
    window.gl = {
      client: {
        isMac: true,
      },
    };

    createWrapper();
  });

  describe.each`
    i     | buttonTitle                       | nonMacTitle                                | buttonType
    ${0}  | ${'Insert suggestion'}            | ${'Insert suggestion'}                     | ${'codeSuggestion'}
    ${1}  | ${'Add bold text (⌘B)'}           | ${'Add bold text (Ctrl+B)'}                | ${'bold'}
    ${2}  | ${'Add italic text (⌘I)'}         | ${'Add italic text (Ctrl+I)'}              | ${'italic'}
    ${3}  | ${'Add strikethrough text (⌘⇧X)'} | ${'Add strikethrough text (Ctrl+Shift+X)'} | ${'strike'}
    ${4}  | ${'Insert a quote'}               | ${'Insert a quote'}                        | ${'blockquote'}
    ${5}  | ${'Insert code'}                  | ${'Insert code'}                           | ${'code'}
    ${6}  | ${'Add a link (⌘K)'}              | ${'Add a link (Ctrl+K)'}                   | ${'link'}
    ${7}  | ${'Add a bullet list'}            | ${'Add a bullet list'}                     | ${'bulletList'}
    ${8}  | ${'Add a numbered list'}          | ${'Add a numbered list'}                   | ${'orderedList'}
    ${9}  | ${'Add a checklist'}              | ${'Add a checklist'}                       | ${'taskList'}
    ${10} | ${'Indent line (⌘])'}             | ${'Indent line (Ctrl+])'}                  | ${'indent'}
    ${11} | ${'Outdent line (⌘[)'}            | ${'Outdent line (Ctrl+[)'}                 | ${'outdent'}
    ${12} | ${'Attach a file or image'}       | ${'Attach a file or image'}                | ${'upload'}
    ${13} | ${'Go full screen'}               | ${'Go full screen'}                        | ${'fullScreen'}
    ${14} | ${'Find and replace'}             | ${'Find and replace'}                      | ${null}
  `('markdown header buttons', ({ i, buttonTitle, nonMacTitle, buttonType }) => {
    it('renders the buttons with the correct title', () => {
      expect(findToolbarButtons().wrappers[i].props('buttonTitle')).toBe(buttonTitle);
    });

    it('renders correct title on non MacOS systems', () => {
      window.gl = { client: { isMac: false } };

      createWrapper();

      expect(findToolbarButtons().wrappers[i].props('buttonTitle')).toBe(nonMacTitle);
    });

    it('passes button type to `trackingProperty` prop', () => {
      expect(findToolbarButtons().wrappers[i].props('trackingProperty')).toBe(buttonType);
    });
  });

  describe('markdown header insert table button renders', () => {
    it('on MacOS', () => {
      expect(findToolbarTableButton()).toBeDefined();
    });

    it('on non MacOS system', () => {
      window.gl = { client: { isMac: false } };

      createWrapper();

      expect(findToolbarTableButton()).toBeDefined();
    });
  });

  it('does not render find and replace button when feature flag is turned off', () => {
    createWrapper({ provide: { glFeatures: { findAndReplace: false } } });
    expect(findToolbarButtons().wrappers[16]).toBeUndefined();
  });

  it('attach file button should have data-button-type attribute', () => {
    const attachButton = findToolbarButtonByProp('icon', 'paperclip');

    // Used for dropzone_input.js as `clickable` property
    // to prevent triggers upload file by clicking on the edge of textarea
    expect(attachButton.attributes('data-button-type')).toBe('attach-file');
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

  it('hides divider in preview mode', () => {
    createWrapper({ props: { previewMarkdown: true } });

    expect(findDividers()).toHaveLength(0);
  });

  it('emits toggle markdown event when clicking preview toggle', async () => {
    findPreviewToggle().vm.$emit('click', true);

    await nextTick();
    expect(wrapper.emitted('showPreview')).toHaveLength(1);

    findPreviewToggle().vm.$emit('click', false);

    await nextTick();
    expect(wrapper.emitted('showPreview')).toHaveLength(2);
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

  describe('markdown table button', () => {
    beforeEach(() => {
      setHTMLFixture('<div class="md-area"><textarea></textarea><div id="root"></div></div>');

      wrapper = mountExtended(HeaderComponent, {
        attachTo: '#root',
        propsData: {
          previewMarkdown: false,
        },
        stubs: { GlToggle },
        provide: {
          glFeatures: {
            findAndReplace: true,
          },
        },
      });
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('renders markdown table template', async () => {
      const tableButton = findToolbarTableButton();

      const button = tableButton.findComponent({ ref: 'table-1-1' });
      await button.trigger('mouseover');
      await button.trigger('click');

      expect(updateText).toHaveBeenCalledWith({
        textArea: document.querySelector('textarea'),
        tag: '| header |\n| ------ |\n|        |',
        cursorOffset: 0,
        wrap: false,
      });
    });
  });

  it('renders suggestion template', () => {
    expect(findToolbarButtonByProp('buttonTitle', 'Insert suggestion').props('tag')).toEqual(
      '```suggestion:-0+0\n{text}\n```',
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

      expect(findToolbarButtons()).toHaveLength(defaultCount - 1);
    });

    it('shows all items by default', () => {
      expect(findToolbarButtons()).toHaveLength(defaultCount);
    });

    it("doesn't render dividers when toolbar buttons past them are restricted", () => {
      createWrapper({
        props: {
          enablePreview: false,
          canSuggest: false,
          restrictedToolBarItems: [
            'quote',
            'strikethrough',
            'bullet-list',
            'numbered-list',
            'task-list',
            'table',
            'attach-file',
            'full-screen',
            'indent',
            'outdent',
          ],
        },
      });
      expect(findDividers()).toHaveLength(2);
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
          newCommentTemplatePaths: ['some/path'],
          glFeatures: {
            savedReplies: true,
          },
        },
      });

      await findCommentTemplatesModal().vm.$emit('select', 'Some saved comment');

      expect(updateText).toHaveBeenCalledWith({
        textArea: document.querySelector('textarea'),
        tag: 'Some saved comment',
        cursorOffset: 0,
        wrap: false,
      });
    });

    it('does not show the saved replies button if newCommentTemplatePaths is not defined', () => {
      createWrapper({
        provide: {
          glFeatures: {
            savedReplies: true,
          },
        },
      });

      expect(findCommentTemplatesModal().exists()).toBe(false);
    });
  });

  describe('find and replace', () => {
    let form;
    let formWrapper;

    const createParentForm = () => {
      form = document.createElement('form');
      const field = document.createElement('div');
      const root = document.createElement('div');
      const textarea = document.createElement('textarea');
      textarea.value = 'lorem ipsum dolor sit amet lorem <img src="prompt">';
      field.classList = 'js-vue-markdown-field';
      form.classList = 'md-area';
      form.appendChild(textarea);
      form.appendChild(field);
      field.appendChild(root);
      document.body.appendChild(form);
      formWrapper = extendedWrapper(createVueTestWrapper(form));
      return root;
    };

    const findFindInput = () => wrapper.findByTestId('find-btn');
    const findCloneDiv = () => formWrapper.findByTestId('find-and-replace-clone');
    const findFindAndReplaceBar = () => wrapper.findByTestId('find-and-replace');
    const findNextButton = () => wrapper.findByTestId('find-next');
    const findPrevButton = () => wrapper.findByTestId('find-prev');
    const findCloseButton = () => wrapper.findByTestId('find-and-replace-close');

    const showFindAndReplace = async () => {
      $(document).triggerHandler('markdown-editor:find-and-replace:show', [$('form')]);
      await nextTick();
    };

    const closeFindAndReplace = async () => {
      const preventDefault = jest.fn();
      findFindInput().vm.$emit('keydown', { preventDefault, key: 'Escape' });
      await nextTick();
      expect(preventDefault).not.toHaveBeenCalled();
    };

    beforeEach(() => {
      createWrapper({ attachTo: createParentForm() });
    });

    afterEach(() => {
      form.parentNode.removeChild(form);
    });

    it('does not emit find and replace event when triggered from another form', () => {
      $(document).triggerHandler('markdown-editor:find-and-replace:show', [
        $(
          '<form><div class="js-vue-markdown-field"><textarea class="markdown-area"></textarea></div></form>',
        ),
      ]);

      expect(findFindAndReplaceBar().exists()).toBe(false);
    });

    it('displays find-and-replace bar when shortcut event is emitted', async () => {
      await showFindAndReplace();
      expect(findFindAndReplaceBar().exists()).toBe(true);
    });

    it('prevents submitting the form when Enter key is pressed', async () => {
      await showFindAndReplace();
      const preventDefault = jest.fn();
      findFindInput().vm.$emit('keydown', { preventDefault, key: 'Enter' });
      expect(preventDefault).toHaveBeenCalled();
    });

    it('closes the find-and-replace bar when Escape key is pressed', async () => {
      await showFindAndReplace();
      expect(findFindAndReplaceBar().exists()).toBe(true);
      await closeFindAndReplace();
      expect(findFindAndReplaceBar().exists()).toBe(false);
    });

    it('embeds a clone to div to color highlighted text', async () => {
      await showFindAndReplace();
      await findFindInput().vm.$emit('keyup', { target: { value: 'my-text' } });
      await nextTick();
      expect(findCloneDiv().exists()).toBe(true);

      // Wait till the highlighting is complete
      await nextTick();

      // Check that closing the find and replace removes the clone div
      await closeFindAndReplace();
      expect(findCloneDiv().exists()).toBe(false);
    });

    it('highlights text when text matches', async () => {
      await showFindAndReplace();

      // Text that does not match
      await findFindInput().vm.$emit('keyup', { target: { value: 'my-text' } });
      await nextTick();

      expect(formWrapper.element.querySelector('.js-highlight')).toBe(null);

      // Text that matches
      await findFindInput().vm.$emit('keyup', { target: { value: 'lorem' } });
      await nextTick();

      expect(formWrapper.element.querySelector('.js-highlight').innerHTML).toBe('lorem');
    });

    it('is not vulnerable to XSS', async () => {
      await showFindAndReplace();
      await findFindInput().vm.$emit('keyup', { target: { value: 'prompt' } });
      await nextTick();

      expect(findCloneDiv().element.innerHTML).toBe(
        'lorem ipsum dolor sit amet lorem &lt;img src="<span class="js-highlight js-highlight-active" style="background-color: rgb(233, 190, 116); display: inline-block;">prompt</span>"&gt;',
      );
    });

    it('displays total number of matches', async () => {
      await showFindAndReplace();

      // Text that does not match
      await findFindInput().vm.$emit('keyup', { target: { value: 'my-text' } });
      await nextTick();

      expect(findFindAndReplaceBar().text()).toBe('No records');

      // Text that matches
      await findFindInput().vm.$emit('keyup', { target: { value: 'lorem' } });
      await nextTick();

      expect(findFindAndReplaceBar().text()).toBe('1 of 2');
    });

    it('highlights first item when there is a match', async () => {
      await showFindAndReplace();

      // Text that matches
      await findFindInput().vm.$emit('keyup', { target: { value: 'lorem' } });
      await nextTick();

      expect(findCloneDiv().element.querySelectorAll('.js-highlight-active')).toHaveLength(1);
    });

    it('allows navigating between matches through next and prev buttons', async () => {
      await showFindAndReplace();

      // Text that matches
      await findFindInput().vm.$emit('keyup', { target: { value: 'lorem' } });
      await nextTick();

      const matches = findCloneDiv().element.querySelectorAll('.js-highlight');

      expect(matches).toHaveLength(2);
      expect(Array.from(matches[0].classList)).toEqual(['js-highlight', 'js-highlight-active']);
      expect(Array.from(matches[1].classList)).toEqual(['js-highlight']);

      findNextButton().vm.$emit('click');
      await nextTick();

      expect(Array.from(matches[0].classList)).toEqual(['js-highlight']);
      expect(Array.from(matches[1].classList)).toEqual(['js-highlight', 'js-highlight-active']);

      findPrevButton().vm.$emit('click');
      await nextTick();

      expect(Array.from(matches[0].classList)).toEqual(['js-highlight', 'js-highlight-active']);
      expect(Array.from(matches[1].classList)).toEqual(['js-highlight']);

      // Click again to navigate to last item
      findPrevButton().vm.$emit('click');
      await nextTick();

      expect(Array.from(matches[0].classList)).toEqual(['js-highlight']);
      expect(Array.from(matches[1].classList)).toEqual(['js-highlight', 'js-highlight-active']);

      // Now that we're at last match, clicking next will bring us back to index 0
      findNextButton().vm.$emit('click');
      await nextTick();

      expect(Array.from(matches[0].classList)).toEqual(['js-highlight', 'js-highlight-active']);
      expect(Array.from(matches[1].classList)).toEqual(['js-highlight']);
    });

    it('is case insensitive', async () => {
      await showFindAndReplace();

      // Text that matches
      await findFindInput().vm.$emit('keyup', { target: { value: 'LoReM' } });
      await nextTick();

      const matches = findCloneDiv().element.querySelectorAll('.js-highlight');
      expect(matches).toHaveLength(2);
    });

    it('should have a close button', async () => {
      await showFindAndReplace();
      expect(findFindInput().exists()).toBe(true);
      findCloseButton().vm.$emit('click', true);
      await nextTick();
      expect(findFindInput().exists()).toBe(false);
    });
  });
});
