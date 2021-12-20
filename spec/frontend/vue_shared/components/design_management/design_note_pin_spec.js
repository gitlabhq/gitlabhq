import { shallowMount } from '@vue/test-utils';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';

describe('Design note pin component', () => {
  let wrapper;

  function createComponent(propsData = {}) {
    wrapper = shallowMount(DesignNotePin, {
      propsData: {
        position: {
          left: '10px',
          top: '10px',
        },
        ...propsData,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('should match the snapshot of note without index', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should match the snapshot of note with index', () => {
    createComponent({ label: 1 });
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should match the snapshot when pin is resolved', () => {
    createComponent({ isResolved: true });
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should match the snapshot when position is absent', () => {
    createComponent({ position: null });
    expect(wrapper.element).toMatchSnapshot();
  });
});
