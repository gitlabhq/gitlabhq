import { shallowMount } from '@vue/test-utils';
import ItemTitle from '~/work_items/components/item_title.vue';

jest.mock('lodash/escape', () => jest.fn((fn) => fn));

const createComponent = ({ title = 'Sample title', disabled = false } = {}) =>
  shallowMount(ItemTitle, {
    propsData: {
      title,
      disabled,
    },
  });

describe('ItemTitle', () => {
  let wrapper;
  const mockUpdatedTitle = 'Updated title';
  const findInputEl = () => wrapper.find('[aria-label="Title"]');

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders title contents', () => {
    expect(findInputEl().attributes()).toMatchObject({
      'data-placeholder': 'Add a title...',
      contenteditable: 'true',
    });
    expect(findInputEl().text()).toBe('Sample title');
  });

  it('renders title contents with editing disabled', () => {
    wrapper = createComponent({
      disabled: true,
    });

    expect(wrapper.classes()).toContain('gl-cursor-not-allowed');
    expect(findInputEl().attributes('contenteditable')).toBe('false');
  });

  it.each`
    eventName          | sourceEvent
    ${'title-changed'} | ${'blur'}
    ${'title-input'}   | ${'keyup'}
  `('emits "$eventName" event on input $sourceEvent', async ({ eventName, sourceEvent }) => {
    findInputEl().element.innerText = mockUpdatedTitle;
    await findInputEl().trigger(sourceEvent);

    expect(wrapper.emitted(eventName)).toBeTruthy();
  });
});
