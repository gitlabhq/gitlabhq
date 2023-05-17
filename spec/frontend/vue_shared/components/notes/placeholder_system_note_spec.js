import { shallowMount } from '@vue/test-utils';
import PlaceholderSystemNote from '~/vue_shared/components/notes/placeholder_system_note.vue';

describe('Placeholder system note component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PlaceholderSystemNote, {
      propsData: {
        note: { body: 'This is a placeholder' },
      },
    });
  };

  it('matches snapshot', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
