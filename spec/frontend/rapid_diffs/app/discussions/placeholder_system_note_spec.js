import { shallowMount } from '@vue/test-utils';
import PlaceholderSystemNote from '~/rapid_diffs/app/discussions/placeholder_system_note.vue';
import TimelineEntryItem from '~/rapid_diffs/app/discussions/timeline_entry_item.vue';

describe('PlaceholderSystemNote', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PlaceholderSystemNote, {
      propsData: {
        note: { body: 'applying command' },
        ...props,
      },
    });
  };

  it('renders the note body inside a timeline entry', () => {
    createComponent();
    expect(wrapper.findComponent(TimelineEntryItem).exists()).toBe(true);
    expect(wrapper.find('em').text()).toBe('applying command');
  });
});
