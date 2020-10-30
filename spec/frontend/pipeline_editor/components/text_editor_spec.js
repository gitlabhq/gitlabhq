import { shallowMount } from '@vue/test-utils';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import { mockCiYml } from '../mock_data';

import TextEditor from '~/pipeline_editor/components/text_editor.vue';

describe('~/pipeline_editor/components/text_editor.vue', () => {
  let wrapper;

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TextEditor, {
      propsData: {
        value: mockCiYml,
        ...props,
      },
    });
  };

  const findEditor = () => wrapper.find(EditorLite);

  it('contains an editor', () => {
    createComponent();

    expect(findEditor().exists()).toBe(true);
  });

  it('editor contains the value provided', () => {
    expect(findEditor().props('value')).toBe(mockCiYml);
  });

  it('editor is readony and configured for .yml', () => {
    expect(findEditor().props('editorOptions')).toEqual({ readOnly: true });
    expect(findEditor().props('fileName')).toBe('*.yml');
  });
});
