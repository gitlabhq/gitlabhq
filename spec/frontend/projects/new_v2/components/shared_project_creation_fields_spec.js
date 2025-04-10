import { nextTick } from 'vue';
import { GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SharedProjectCreationFields from '~/projects/new_v2/components/shared_project_creation_fields.vue';
import NewProjectDestinationSelect from '~/projects/new_v2/components/project_destination_select.vue';

describe('Project creation form fields component', () => {
  let wrapper;

  const defaultProps = {
    namespace: {
      id: '1',
      fullPath: 'root',
      isPersonal: true,
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SharedProjectCreationFields, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlFormInput,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findProjectNameInput = () => wrapper.findByTestId('project-name-input');
  const findProjectSlugInput = () => wrapper.findByTestId('project-slug-input');
  const findNamespaceSelect = () => wrapper.findComponent(NewProjectDestinationSelect);

  it('updates project slug according to a project name', async () => {
    // NOTE: vue3 test needs the .setValue(value) and the vm.$emit('input'),
    // while the vue2 needs either .setValue(value) or vm.$emit('input', value)
    const value = 'My Awesome Project 123';
    findProjectNameInput().setValue(value);
    findProjectNameInput().vm.$emit('input', value);
    await nextTick();

    expect(findProjectSlugInput().element.value).toBe('my-awesome-project-123');
  });

  it('emits namespace change', () => {
    findNamespaceSelect().vm.$emit('onSelectNamespace', {
      id: '2',
      fullPath: 'group/subgroup',
      isPersonal: false,
    });

    expect(wrapper.emitted('onSelectNamespace')).toHaveLength(1);
    expect(wrapper.emitted('onSelectNamespace')[0][0]).toEqual({
      id: '2',
      fullPath: 'group/subgroup',
      isPersonal: false,
    });
  });

  describe('validation', () => {
    it('shows an error message when project name is cleared', async () => {
      findProjectNameInput().setValue('');
      findProjectNameInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('project-name-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe('Please enter project name.');
    });

    it('shows an error message when slug is cleared', async () => {
      findProjectSlugInput().setValue('');
      findProjectSlugInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('project-slug-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe('Please enter project slug.');
    });
  });
});
