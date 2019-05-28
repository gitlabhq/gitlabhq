import { shallowMount, createLocalVue } from '@vue/test-utils';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

describe(`TimelineEntryItem`, () => {
  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(TimelineEntryItem, {
      localVue,
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders correctly', () => {
    factory();

    expect(wrapper.is('.timeline-entry')).toBe(true);

    expect(wrapper.contains('.timeline-entry-inner')).toBe(true);
  });

  it('accepts default slot', () => {
    const dummyContent = '<p>some content</p>';
    factory({
      slots: {
        default: dummyContent,
      },
    });

    const content = wrapper.find('.timeline-entry-inner :first-child');

    expect(content.html()).toBe(dummyContent);
  });
});
