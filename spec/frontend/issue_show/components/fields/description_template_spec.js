import Vue from 'vue';
import descriptionTemplate from '~/issue_show/components/fields/description_template.vue';

describe('Issue description template component', () => {
  let vm;
  let formState;

  beforeEach(() => {
    const Component = Vue.extend(descriptionTemplate);
    formState = {
      description: 'test',
    };

    vm = new Component({
      propsData: {
        formState,
        issuableTemplates: {
          test: [{ name: 'test', id: 'test', project_path: '/', namespace_path: '/' }],
        },
        projectId: 1,
        projectPath: '/',
        projectNamespace: '/',
      },
    }).$mount();
  });

  it('renders templates as JSON array in data attribute', () => {
    expect(vm.$el.querySelector('.js-issuable-selector').getAttribute('data-data')).toBe(
      '{"test":[{"name":"test","id":"test","project_path":"/","namespace_path":"/"}]}',
    );
  });

  it('updates formState when changing template', () => {
    vm.issuableTemplate.editor.setValue('test new template');

    expect(formState.description).toBe('test new template');
  });

  it('returns formState description with editor getValue', () => {
    formState.description = 'testing new template';

    expect(vm.issuableTemplate.editor.getValue()).toBe('testing new template');
  });
});
