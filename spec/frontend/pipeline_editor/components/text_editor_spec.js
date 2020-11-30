import { shallowMount } from '@vue/test-utils';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import { mockCiYml } from '../mock_data';

import TextEditor from '~/pipeline_editor/components/text_editor.vue';

describe('~/pipeline_editor/components/text_editor.vue', () => {
  let wrapper;
  const editorReadyListener = jest.fn();

  const createComponent = (attrs = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TextEditor, {
      attrs: {
        value: mockCiYml,
        ...attrs,
      },
      listeners: {
        'editor-ready': editorReadyListener,
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

  it('editor is configured for .yml', () => {
    expect(findEditor().props('fileName')).toBe('*.yml');
  });

  it('bubbles up events', () => {
    findEditor().vm.$emit('editor-ready');

    expect(editorReadyListener).toHaveBeenCalled();
  });
});
