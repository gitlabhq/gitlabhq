import { mount } from '@vue/test-utils';
import { Document } from 'yaml';
import YamlEditor from '~/pipeline_wizard/components/editor.vue';
import SourceEditor from '~/editor/source_editor';

describe('Pages Yaml Editor wrapper', () => {
  let wrapper;

  const defaultDoc = new Document({ foo: 'bar' });

  const defaultOptions = {
    propsData: { doc: defaultDoc, filename: 'foo.yml' },
  };

  const getLatestValue = () => {
    const latest = wrapper.emitted('update:yaml').pop();
    return latest[0];
  };

  describe('mount hook', () => {
    beforeEach(() => {
      jest.spyOn(SourceEditor.prototype, 'createInstance');

      wrapper = mount(YamlEditor, defaultOptions);
    });

    it('creates a source editor instance', () => {
      expect(SourceEditor.prototype.createInstance).toHaveBeenCalledWith({
        el: wrapper.element,
        blobPath: 'foo.yml',
        language: 'yaml',
      });
    });

    it('editor is mounted in the wrapper', () => {
      expect(wrapper.find('.gl-source-editor.monaco-editor').exists()).toBe(true);
    });

    it("causes the editor's value to be set to the stringified document", () => {
      expect(getLatestValue()).toEqual(defaultDoc.toString());
    });
  });

  describe('watchers', () => {
    beforeEach(() => {
      wrapper = mount(YamlEditor, defaultOptions);
    });

    describe('doc', () => {
      const doc = new Document({ baz: ['bar'] });

      it('emits an update:yaml event with the yaml representation of doc', async () => {
        await wrapper.setProps({ doc });

        expect(getLatestValue()).toEqual(doc.toString());
      });

      it('does not cause the touch event to be emitted', () => {
        wrapper.setProps({ doc });
        expect(wrapper.emitted('touch')).toBeUndefined();
      });
    });

    describe('highlight', () => {
      const highlight = 'foo';

      beforeEach(() => {
        wrapper = mount(YamlEditor, defaultOptions);
      });

      it('calls editor.highlight(path, keep=true)', async () => {
        const highlightSpy = jest.spyOn(wrapper.vm.yamlEditorExtension.obj, 'highlight');
        await wrapper.setProps({ highlight });
        expect(highlightSpy).toHaveBeenCalledWith(expect.anything(), highlight, true);
      });
    });
  });
});
