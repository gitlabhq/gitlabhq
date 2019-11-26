import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';
import HeaderComponent from '~/vue_shared/components/markdown/header.vue';
import ToolbarButton from '~/vue_shared/components/markdown/toolbar_button.vue';

describe('Markdown field header component', () => {
  let wrapper;

  const createWrapper = props => {
    wrapper = shallowMount(HeaderComponent, {
      propsData: {
        previewMarkdown: false,
        ...props,
      },
      sync: false,
      attachToDocument: true,
    });
  };

  const findToolbarButtons = () => wrapper.findAll(ToolbarButton);
  const findToolbarButtonByProp = (prop, value) =>
    findToolbarButtons()
      .filter(button => button.props(prop) === value)
      .at(0);

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders markdown header buttons', () => {
    const buttons = [
      'Add bold text',
      'Add italic text',
      'Insert a quote',
      'Insert suggestion',
      'Insert code',
      'Add a link',
      'Add a bullet list',
      'Add a numbered list',
      'Add a task list',
      'Add a table',
      'Go full screen',
    ];
    const elements = findToolbarButtons();

    elements.wrappers.forEach((buttonEl, index) => {
      expect(buttonEl.props('buttonTitle')).toBe(buttons[index]);
    });
  });

  it('renders `write` link as active when previewMarkdown is false', () => {
    expect(wrapper.find('li:nth-child(1)').classes()).toContain('active');
  });

  it('renders `preview` link as active when previewMarkdown is true', () => {
    createWrapper({ previewMarkdown: true });

    expect(wrapper.find('li:nth-child(2)').classes()).toContain('active');
  });

  it('emits toggle markdown event when clicking preview', () => {
    wrapper.find('.js-preview-link').trigger('click');

    expect(wrapper.emitted('preview-markdown').length).toEqual(1);

    wrapper.find('.js-write-link').trigger('click');

    expect(wrapper.emitted('write-markdown').length).toEqual(1);
  });

  it('does not emit toggle markdown event when triggered from another form', () => {
    $(document).triggerHandler('markdown-preview:show', [
      $(
        '<form><div class="js-vue-markdown-field"><textarea class="markdown-area"></textarea></div></form>',
      ),
    ]);

    expect(wrapper.emitted('preview-markdown')).toBeFalsy();
    expect(wrapper.emitted('write-markdown')).toBeFalsy();
  });

  it('blurs preview link after click', () => {
    const link = wrapper.find('li:nth-child(2) button');
    jest.spyOn(HTMLElement.prototype, 'blur').mockImplementation();

    link.trigger('click');

    expect(link.element.blur).toHaveBeenCalled();
  });

  it('renders markdown table template', () => {
    const tableButton = findToolbarButtonByProp('icon', 'table');

    expect(tableButton.props('tag')).toEqual(
      '| header | header |\n| ------ | ------ |\n| cell | cell |\n| cell | cell |',
    );
  });

  it('renders suggestion template', () => {
    expect(findToolbarButtonByProp('buttonTitle', 'Insert suggestion').props('tag')).toEqual(
      '```suggestion:-0+0\n{text}\n```',
    );
  });

  it('does not render suggestion button if `canSuggest` is set to false', () => {
    createWrapper({
      canSuggest: false,
    });

    expect(wrapper.find('.js-suggestion-btn').exists()).toBe(false);
  });
});
