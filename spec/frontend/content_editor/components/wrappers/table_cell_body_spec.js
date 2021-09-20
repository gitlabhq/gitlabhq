import { shallowMount } from '@vue/test-utils';
import TableCellBaseWrapper from '~/content_editor/components/wrappers/table_cell_base.vue';
import TableCellBodyWrapper from '~/content_editor/components/wrappers/table_cell_body.vue';
import { createTestEditor } from '../../test_utils';

describe('content/components/wrappers/table_cell_body', () => {
  let wrapper;
  let editor;
  let getPos;

  const createWrapper = async () => {
    wrapper = shallowMount(TableCellBodyWrapper, {
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
      cellType: 'td',
    });
  });
});
