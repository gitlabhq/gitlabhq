import Vue from 'vue';
import $ from 'jquery';
import headerComponent from '~/vue_shared/components/markdown/header.vue';

describe('Markdown field header component', () => {
  let vm;

  beforeEach(done => {
    const Component = Vue.extend(headerComponent);

    vm = new Component({
      propsData: {
        previewMarkdown: false,
      },
    }).$mount();

    Vue.nextTick(done);
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
    const elements = vm.$el.querySelectorAll('.toolbar-btn');

    elements.forEach((buttonEl, index) => {
      expect(buttonEl.getAttribute('data-original-title')).toBe(buttons[index]);
    });
  });

  it('renders `write` link as active when previewMarkdown is false', () => {
    expect(vm.$el.querySelector('li:nth-child(1)').classList.contains('active')).toBeTruthy();
  });

  it('renders `preview` link as active when previewMarkdown is true', done => {
    vm.previewMarkdown = true;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('li:nth-child(2)').classList.contains('active')).toBeTruthy();

      done();
    });
  });

  it('emits toggle markdown event when clicking preview', () => {
    jest.spyOn(vm, '$emit').mockImplementation();

    vm.$el.querySelector('.js-preview-link').click();

    expect(vm.$emit).toHaveBeenCalledWith('preview-markdown');

    vm.$el.querySelector('.js-write-link').click();

    expect(vm.$emit).toHaveBeenCalledWith('write-markdown');
  });

  it('does not emit toggle markdown event when triggered from another form', () => {
    jest.spyOn(vm, '$emit').mockImplementation();

    $(document).triggerHandler('markdown-preview:show', [
      $(
        '<form><div class="js-vue-markdown-field"><textarea class="markdown-area"></textarea></div></form>',
      ),
    ]);

    expect(vm.$emit).not.toHaveBeenCalled();
  });

  it('blurs preview link after click', () => {
    const link = vm.$el.querySelector('li:nth-child(2) button');
    jest.spyOn(HTMLElement.prototype, 'blur').mockImplementation();

    link.click();

    expect(link.blur).toHaveBeenCalled();
  });

  it('renders markdown table template', () => {
    expect(vm.mdTable).toEqual(
      '| header | header |\n| ------ | ------ |\n| cell | cell |\n| cell | cell |',
    );
  });

  it('renders suggestion template', () => {
    vm.lineContent = 'Some content';

    expect(vm.mdSuggestion).toEqual('```suggestion:-0+0\n{text}\n```');
  });

  it('does not render suggestion button if `canSuggest` is set to false', () => {
    vm.canSuggest = false;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.qa-suggestion-btn')).toBe(null);
    });
  });
});
