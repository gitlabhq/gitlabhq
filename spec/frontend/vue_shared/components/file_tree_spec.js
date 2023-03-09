import { shallowMount } from '@vue/test-utils';
import { pick } from 'lodash';
import FileTree from '~/vue_shared/components/file_tree.vue';

const MockFileRow = {
  name: 'MockFileRow',
  render() {
    return this.$slots.default;
  },
};

const TEST_LEVEL = 4;
const TEST_EXTA_ARGS = {
  foo: 'lorem-ipsum',
  bar: 'zoo',
};

describe('File Tree component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(FileTree, {
      propsData: { level: TEST_LEVEL, fileRowComponent: MockFileRow, ...props },
      attrs: { ...TEST_EXTA_ARGS },
    });
  };

  const findFileRow = () => wrapper.findComponent(MockFileRow);
  const findChildrenTrees = () => wrapper.findAllComponents(FileTree).wrappers.slice(1);
  const findChildrenTreeProps = () =>
    findChildrenTrees().map((x) => ({
      ...x.props(),
      ...pick(x.attributes(), Object.keys(TEST_EXTA_ARGS)),
    }));

  describe('file row component', () => {
    beforeEach(() => {
      createComponent({ file: {} });
    });

    it('renders file row component', () => {
      expect(findFileRow().exists()).toEqual(true);
    });

    it('contains the required attribute keys', () => {
      const fileRow = findFileRow();

      // Checking strings b/c value in attributes are always strings
      expect(fileRow.attributes()).toEqual({
        file: {}.toString(),
        level: TEST_LEVEL.toString(),
        ...TEST_EXTA_ARGS,
      });
    });
  });

  describe('file tree', () => {
    const createChildren = () => [{ id: 1 }, { id: 2 }];
    const createChildrenExpectation = (props = {}) =>
      createChildren().map((file) => ({
        fileRowComponent: MockFileRow,
        file,
        ...TEST_EXTA_ARGS,
        ...props,
      }));

    it.each`
      key           | value    | desc                             | expectedChildren
      ${'isHeader'} | ${true}  | ${'is shown if file is header'}  | ${createChildrenExpectation({ level: 0 })}
      ${'opened'}   | ${true}  | ${'is shown if file is open'}    | ${createChildrenExpectation({ level: TEST_LEVEL + 1 })}
      ${'isHeader'} | ${false} | ${'is hidden if file is header'} | ${[]}
      ${'opened'}   | ${false} | ${'is hidden if file is open'}   | ${[]}
    `('$desc', ({ key, value, expectedChildren }) => {
      createComponent({
        file: {
          [key]: value,
          tree: createChildren(),
        },
      });

      expect(findChildrenTreeProps()).toEqual(expectedChildren);
    });
  });
});
