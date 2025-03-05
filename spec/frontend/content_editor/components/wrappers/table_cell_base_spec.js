import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import TableCellBaseWrapper from '~/content_editor/components/wrappers/table_cell_base.vue';
import { createTestEditor } from '../../test_utils';

describe('content/components/wrappers/table_cell_base', () => {
  let wrapper;
  let editor;
  let node;

  const createWrapper = (propsData = { cellType: 'td' }) => {
    wrapper = mountExtended(TableCellBaseWrapper, {
      propsData: {
        editor,
        node,
        getPos: () => 0,
        ...propsData,
      },
      stubs: {
        NodeViewWrapper: stubComponent(NodeViewWrapper),
        NodeViewContent: stubComponent(NodeViewContent),
      },
    });
  };

  beforeEach(() => {
    node = {
      attrs: {},
    };
    editor = createTestEditor({});
  });

  it('renders a td node-view-wrapper with relative position', () => {
    createWrapper();
    expect(wrapper.findComponent(NodeViewWrapper).classes()).toContain('gl-relative');
    expect(wrapper.findComponent(NodeViewWrapper).props().as).toBe('td');
  });
});
