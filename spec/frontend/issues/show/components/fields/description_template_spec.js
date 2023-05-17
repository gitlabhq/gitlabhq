import { shallowMount } from '@vue/test-utils';
import descriptionTemplate from '~/issues/show/components/fields/description_template.vue';

describe('Issue description template component with templates as hash', () => {
  let wrapper;
  const defaultOptions = {
    propsData: {
      value: 'test',
      issuableTemplates: {
        test: [{ name: 'test', id: 'test', project_path: '/', namespace_path: '/' }],
      },
      projectId: 1,
      projectPath: '/',
      namespacePath: '/',
      projectNamespace: '/',
    },
  };

  const findIssuableSelector = () => wrapper.find('.js-issuable-selector');

  const createComponent = (options = defaultOptions) => {
    wrapper = shallowMount(descriptionTemplate, options);
  };

  it('renders templates as JSON hash in data attribute', () => {
    createComponent();
    expect(findIssuableSelector().attributes('data-data')).toBe(
      '{"test":[{"name":"test","id":"test","project_path":"/","namespace_path":"/"}]}',
    );
  });

  it('emits input event', () => {
    createComponent();
    wrapper.vm.issuableTemplate.editor.setValue('test new template');

    expect(wrapper.emitted('input')).toEqual([['test new template']]);
  });

  it('returns value with editor getValue', () => {
    createComponent();
    expect(wrapper.vm.issuableTemplate.editor.getValue()).toBe('test');
  });

  describe('Issue description template component with templates as array', () => {
    it('renders templates as JSON array in data attribute', () => {
      createComponent({
        propsData: {
          value: 'test',
          issuableTemplates: [{ name: 'test', id: 'test', project_path: '/', namespace_path: '/' }],
          projectId: 1,
          projectPath: '/',
          namespacePath: '/',
          projectNamespace: '/',
        },
      });
      expect(findIssuableSelector().attributes('data-data')).toBe(
        '[{"name":"test","id":"test","project_path":"/","namespace_path":"/"}]',
      );
    });
  });
});
