import { shallowMount } from '@vue/test-utils';
import TableCellBaseWrapper from '~/content_editor/components/wrappers/table_cell_base.vue';
import TableCellBodyWrapper from '~/content_editor/components/wrappers/table_cell_body.vue';
import { createTestEditor } from '../../test_utils';

describe('content/components/wrappers/table_cell_body', () => {
  let wrapper;
  let editor;
  let node;

  const createWrapper = () => {
    wrapper = shallowMount(TableCellBodyWrapper, {
      propsData: {
        editor,
        node,
      },
    });
  };

  beforeEach(() => {
    node = {};
    editor = createTestEditor({});
  });

  it('renders a TableCellBase component', () => {
    createWrapper();
    expect(wrapper.findComponent(TableCellBaseWrapper).props()).toEqual({
      editor,
      node,
      cellType: 'td',
    });
  });
});
