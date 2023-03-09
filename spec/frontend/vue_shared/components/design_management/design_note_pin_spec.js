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

  it('applies `on-image` class when isOnImage is true', () => {
    createComponent({ isOnImage: true });

    expect(wrapper.find('.on-image').exists()).toBe(true);
  });

  it('applies `draft` class when isDraft is true', () => {
    createComponent({ isDraft: true });

    expect(wrapper.find('.draft').exists()).toBe(true);
  });

  describe('size', () => {
    it('is `sm` it applies `small` class', () => {
      createComponent({ size: 'sm' });
      expect(wrapper.find('.small').exists()).toBe(true);
    });

    it('is `md` it applies no size class', () => {
      createComponent({ size: 'md' });
      expect(wrapper.find('.small').exists()).toBe(false);
      expect(wrapper.find('.medium').exists()).toBe(false);
    });

    it('throws when passed any other value except `sm` or `md`', () => {
      jest.spyOn(console, 'error').mockImplementation(() => {});

      createComponent({ size: 'lg' });

      // eslint-disable-next-line no-console
      expect(console.error).toHaveBeenCalled();
    });
  });

  describe('ariaLabel', () => {
    describe('when value is passed', () => {
      it('overrides default aria-label', () => {
        const ariaLabel = 'Aria Label';

        createComponent({ ariaLabel });

        const button = wrapper.find('button');

        expect(button.attributes('aria-label')).toBe(ariaLabel);
      });
    });

    describe('when no value is passed', () => {
      it('shows new note label as aria-label when label is absent', () => {
        createComponent({ label: null });

        const button = wrapper.find('button');

        expect(button.attributes('aria-label')).toBe('Comment form position');
      });

      it('shows label position as aria-label when label is present', () => {
        const label = 1;

        createComponent({ label, isNewNote: false });

        const button = wrapper.find('button');

        expect(button.attributes('aria-label')).toBe(`Comment '${label}' position`);
      });
    });
  });
});
