import { mount } from '@vue/test-utils';
import DropdownSearchInputComponent from '~/vue_shared/components/dropdown/dropdown_search_input.vue';

describe('DropdownSearchInputComponent', () => {
  let wrapper;

  const defaultProps = {
    placeholderText: 'Search something',
  };
  const buildVM = (propsData = defaultProps) => {
    wrapper = mount(DropdownSearchInputComponent, {
      propsData,
    });
  };
  const findInputEl = () => wrapper.find('.dropdown-input-field');

  beforeEach(() => {
    buildVM();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders input element with type `search`', () => {
      expect(findInputEl().exists()).toBe(true);
      expect(findInputEl().attributes('type')).toBe('search');
    });

    it('renders search icon element', () => {
      expect(wrapper.find('.fa-search.dropdown-input-search').exists()).toBe(true);
    });

    it('renders clear search icon element', () => {
      expect(wrapper.find('.fa-times.dropdown-input-clear.js-dropdown-input-clear').exists()).toBe(
        true,
      );
    });

    it('displays custom placeholder text', () => {
      expect(findInputEl().attributes('placeholder')).toBe(defaultProps.placeholderText);
    });

    it('focuses input element when focused property equals true', () => {
      const inputEl = findInputEl().element;

      jest.spyOn(inputEl, 'focus');

      wrapper.setProps({ focused: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(inputEl.focus).toHaveBeenCalled();
      });
    });
  });
});
