import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import FileRowExtra from '~/ide/components/file_row_extra.vue';
import IdeFileRow from '~/ide/components/ide_file_row.vue';
import { createStore } from '~/ide/stores';
import FileRow from '~/vue_shared/components/file_row.vue';

Vue.use(Vuex);

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
      ...options,
    });
  };

  const findFileRowExtra = () => wrapper.findComponent(FileRowExtra);
  const findFileRow = () => wrapper.findComponent(FileRow);
  const hasDropdownOpen = () => findFileRowExtra().props('dropdownOpen');

  it('fileRow component has listeners', async () => {
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

    await nextTick();
    expect(toggleTreeOpen).toHaveBeenCalled();
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
    beforeEach(async () => {
      createComponent();

      findFileRowExtra().vm.$emit('toggle', true);

      await nextTick();
    });

    it('shows open dropdown', () => {
      expect(hasDropdownOpen()).toBe(true);
    });

    it('hides dropdown when mouseleave', async () => {
      findFileRow().vm.$emit('mouseleave');

      await nextTick();
      expect(hasDropdownOpen()).toEqual(false);
    });

    it('hides dropdown on toggle', async () => {
      findFileRowExtra().vm.$emit('toggle', false);

      await nextTick();
      expect(hasDropdownOpen()).toEqual(false);
    });
  });
});
