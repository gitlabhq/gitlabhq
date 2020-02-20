import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import IdeFileRow from '~/ide/components/ide_file_row.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowExtra from '~/ide/components/file_row_extra.vue';
import { createStore } from '~/ide/stores';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_EXTRA_PROPS = {
  testattribute: 'abc',
};

const defaultComponentProps = (type = 'tree') => ({
  level: 4,
  file: {
    type,
    name: 'js',
  },
});

describe('Ide File Row component', () => {
  let wrapper;

  const createComponent = (props = {}, options = {}) => {
    wrapper = mount(IdeFileRow, {
      propsData: {
        ...defaultComponentProps(),
        ...props,
      },
      store: createStore(),
      localVue,
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findFileRowExtra = () => wrapper.find(FileRowExtra);
  const findFileRow = () => wrapper.find(FileRow);
  const hasDropdownOpen = () => findFileRowExtra().props('dropdownOpen');

  it('fileRow component has listeners', () => {
    const toggleTreeOpen = jest.fn();
    createComponent(
      {},
      {
        listeners: {
          toggleTreeOpen,
        },
      },
    );

    findFileRow().vm.$emit('toggleTreeOpen');

    return wrapper.vm.$nextTick().then(() => {
      expect(toggleTreeOpen).toHaveBeenCalled();
    });
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent(TEST_EXTRA_PROPS);
    });

    it('renders file row component', () => {
      const fileRow = findFileRow();

      expect(fileRow.props()).toEqual(expect.objectContaining(defaultComponentProps()));
      expect(fileRow.attributes()).toEqual(expect.objectContaining(TEST_EXTRA_PROPS));
    });

    it('renders file row extra', () => {
      const extra = findFileRowExtra();

      expect(extra.exists()).toBe(true);
      expect(extra.props()).toEqual({
        file: defaultComponentProps().file,
        dropdownOpen: false,
      });
    });
  });

  describe('with open dropdown', () => {
    beforeEach(() => {
      createComponent();

      findFileRowExtra().vm.$emit('toggle', true);

      return wrapper.vm.$nextTick();
    });

    it('shows open dropdown', () => {
      expect(hasDropdownOpen()).toBe(true);
    });

    it('hides dropdown when mouseleave', () => {
      findFileRow().vm.$emit('mouseleave');

      return wrapper.vm.$nextTick().then(() => {
        expect(hasDropdownOpen()).toEqual(false);
      });
    });

    it('hides dropdown on toggle', () => {
      findFileRowExtra().vm.$emit('toggle', false);

      return wrapper.vm.$nextTick().then(() => {
        expect(hasDropdownOpen()).toEqual(false);
      });
    });
  });
});
