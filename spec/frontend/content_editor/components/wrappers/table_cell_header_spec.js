import { shallowMount } from '@vue/test-utils';
import TableCellBaseWrapper from '~/content_editor/components/wrappers/table_cell_base.vue';
import TableCellHeaderWrapper from '~/content_editor/components/wrappers/table_cell_header.vue';
import { createTestEditor } from '../../test_utils';

describe('content/components/wrappers/table_cell_header', () => {
  let wrapper;
  let editor;
  let getPos;

  const createWrapper = async () => {
    wrapper = shallowMount(TableCellHeaderWrapper, {
      propsData: {
        editor,
        getPos,
      },
    });
  };

  beforeEach(() => {
    getPos = jest.fn();
    editor = createTestEditor({});
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a TableCellBase component', () => {
    createWrapper();
    expect(wrapper.findComponent(TableCellBaseWrapper).props()).toEqual({
      editor,
      getPos,
      cellType: 'th',
    });
  });
});
