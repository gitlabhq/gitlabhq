import { shallowMount } from '@vue/test-utils';
import { escape } from 'lodash';
import ItemTitle from '~/work_items/components/item_title.vue';

const createComponent = ({ title = 'Sample title', disabled = false, useH1 = false } = {}) =>
  shallowMount(ItemTitle, {
    propsData: {
      title,
      disabled,
      useH1,
    },
  });

describe('ItemTitle', () => {
  let wrapper;
  const mockUpdatedTitle = 'Updated title';
  const findInputEl = () => wrapper.find('[aria-label="Title"]');

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders title contents', () => {
    expect(findInputEl().attributes()).toMatchObject({
      'data-placeholder': 'Add a title...',
      contenteditable: 'true',
    });
    expect(findInputEl().text()).toBe('Sample title');
  });

  it('renders H1 if useH1 is true, otherwise renders H2', () => {
    expect(wrapper.element.tagName).toBe('H2');
    wrapper = createComponent({ useH1: true });
    expect(wrapper.element.tagName).toBe('H1');
  });

  it('renders title contents with editing disabled', () => {
    wrapper = createComponent({
      disabled: true,
    });

    expect(wrapper.classes()).toContain('gl-cursor-text');
    expect(findInputEl().attributes('contenteditable')).toBe('false');
  });

  it.each`
    eventName          | sourceEvent
    ${'title-changed'} | ${'blur'}
    ${'title-input'}   | ${'keyup'}
  `('emits "$eventName" event on input $sourceEvent', async ({ eventName, sourceEvent }) => {
    findInputEl().element.innerText = mockUpdatedTitle;
    await findInputEl().trigger(sourceEvent);

    expect(wrapper.emitted(eventName)).toBeDefined();
  });

  it('renders only the text content from clipboard', () => {
    const htmlContent = '<strong>bold text</strong>';
    const buildClipboardData = (data = {}) => ({
      clipboardData: {
        getData(mimeType) {
          return data[mimeType];
        },
        types: Object.keys(data),
      },
    });

    findInputEl().trigger(
      'paste',
      buildClipboardData({
        html: htmlContent,
        text: htmlContent,
      }),
    );
    expect(findInputEl().element.innerHTML).toBe(escape(htmlContent));
  });
});
