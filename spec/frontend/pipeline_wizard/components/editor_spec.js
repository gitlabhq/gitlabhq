import { mount } from '@vue/test-utils';
import { Document } from 'yaml';
import YamlEditor from '~/pipeline_wizard/components/editor.vue';

describe('Pages Yaml Editor wrapper', () => {
  let wrapper;

  const defaultOptions = {
    propsData: { doc: new Document({ foo: 'bar' }), filename: 'foo.yml' },
  };

  describe('mount hook', () => {
    beforeEach(() => {
      wrapper = mount(YamlEditor, defaultOptions);
    });

    it('editor is mounted', () => {
      expect(wrapper.vm.editor).not.toBeUndefined();
      expect(wrapper.find('.gl-source-editor').exists()).toBe(true);
    });
  });

  describe('watchers', () => {
    describe('doc', () => {
      const doc = new Document({ baz: ['bar'] });

      beforeEach(() => {
        wrapper = mount(YamlEditor, defaultOptions);
      });

      it("causes the editor's value to be set to the stringified document", async () => {
        await wrapper.setProps({ doc });
        expect(wrapper.vm.editor.getValue()).toEqual(doc.toString());
      });

      it('emits an update:yaml event with the yaml representation of doc', async () => {
        await wrapper.setProps({ doc });
        const changeEvents = wrapper.emitted('update:yaml');
        expect(changeEvents[2]).toEqual([doc.toString()]);
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
