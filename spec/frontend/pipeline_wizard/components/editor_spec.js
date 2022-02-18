import { mount } from '@vue/test-utils';
import { Document } from 'yaml';
import YamlEditor from '~/pipeline_wizard/components/editor.vue';

describe('Pages Yaml Editor wrapper', () => {
  const defaultOptions = {
    propsData: { doc: new Document({ foo: 'bar' }), filename: 'foo.yml' },
  };

  describe('mount hook', () => {
    const wrapper = mount(YamlEditor, defaultOptions);

    it('editor is mounted', () => {
      expect(wrapper.vm.editor).not.toBeFalsy();
      expect(wrapper.find('.gl-source-editor').exists()).toBe(true);
    });
  });

  describe('watchers', () => {
    describe('doc', () => {
      const doc = new Document({ baz: ['bar'] });
      let wrapper;

      beforeEach(() => {
        wrapper = mount(YamlEditor, defaultOptions);
      });

      afterEach(() => {
        wrapper.destroy();
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
        expect(wrapper.emitted('touch')).not.toBeTruthy();
      });
    });

    describe('highlight', () => {
      const highlight = 'foo';
      const wrapper = mount(YamlEditor, defaultOptions);

      it('calls editor.highlight(path, keep=true)', async () => {
        const highlightSpy = jest.spyOn(wrapper.vm.yamlEditorExtension.obj, 'highlight');
        await wrapper.setProps({ highlight });
        expect(highlightSpy).toHaveBeenCalledWith(expect.anything(), highlight, true);
      });
    });
  });

  describe('events', () => {
    const wrapper = mount(YamlEditor, defaultOptions);

    it('emits touch if content is changed in editor', async () => {
      await wrapper.vm.editor.setValue('foo: boo');
      expect(wrapper.emitted('touch')).toBeTruthy();
    });
  });
});
