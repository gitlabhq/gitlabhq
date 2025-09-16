import { nextTick } from 'vue';
import { GlFormInput, GlFormSelect } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';
import SharedProjectCreationFields from '~/projects/new_v2/components/shared_project_creation_fields.vue';
import NewProjectDestinationSelect from '~/projects/new_v2/components/project_destination_select.vue';
import ProjectNameValidator from '~/projects/new_v2/components/project_name_validator.vue';
import { DEPLOYMENT_TARGET_SELECTIONS } from '~/projects/new_v2/form_constants';

describe('Project creation form fields component', () => {
  let wrapper;

  const defaultProps = {
    namespace: {
      id: '1',
      fullPath: 'root',
      isPersonal: true,
    },
  };

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(SharedProjectCreationFields, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...provide,
      },
      stubs: {
        GlFormInput,
        GlFormSelect,
      },
    });
  };

  const findProjectNameInput = () => wrapper.findByTestId('project-name-input');
  const findProjectSlugInput = () => wrapper.findByTestId('project-slug-input');
  const findNamespaceSelect = () => wrapper.findComponent(NewProjectDestinationSelect);
  const findDeploymentTargetSelect = () => wrapper.findByTestId('deployment-target-select');
  const findKubernetesHelpLink = () => wrapper.findByTestId('kubernetes-help-link');
  const findVisibilitySelector = () => wrapper.findComponent(SingleChoiceSelector);
  const findProjectNameValidator = () => wrapper.findComponent(ProjectNameValidator);
  const findPrivateVisibilityLevelOption = () => wrapper.findByTestId('private-visibility-level');
  const findInternalVisibilityLevelOption = () => wrapper.findByTestId('internal-visibility-level');
  const findPublicVisibilityLevelOption = () => wrapper.findByTestId('public-visibility-level');

  describe('target select', () => {
    it('renders the optional deployment target select', () => {
      createComponent();

      expect(findDeploymentTargetSelect().exists()).toBe(true);
      expect(findKubernetesHelpLink().exists()).toBe(false);
    });

    it('has all the options', () => {
      createComponent();

      expect(findDeploymentTargetSelect().props('options')).toEqual(DEPLOYMENT_TARGET_SELECTIONS);
    });
  });

  it('updates project slug according to a project name', async () => {
    createComponent();

    // NOTE: vue3 test needs the .setValue(value) and the vm.$emit('input'),
    // while the vue2 needs either .setValue(value) or vm.$emit('input', value)
    const value = 'My Awesome Project 123';
    findProjectNameInput().setValue(value);
    findProjectNameInput().vm.$emit('input', value);
    await nextTick();

    expect(findProjectSlugInput().element.value).toBe('my-awesome-project-123');
  });

  it('emits namespace change', () => {
    createComponent();

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
      createComponent();

      findProjectNameInput().setValue('');
      findProjectNameInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('project-name-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe('Please enter project name.');
    });

    it('shows an error message when slug is cleared', async () => {
      createComponent();

      findProjectSlugInput().setValue('');
      findProjectSlugInput().trigger('blur');
      await nextTick();

      const formGroup = wrapper.findByTestId('project-slug-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe('Please enter project slug.');
    });

    it('renders a project name availability alert', async () => {
      createComponent();

      findProjectNameInput().setValue('Test Name');
      findProjectNameInput().trigger('blur');
      findProjectSlugInput().setValue('test-name');
      findProjectSlugInput().trigger('blur');

      await nextTick();

      expect(findProjectNameValidator().exists()).toBe(true);
      expect(findProjectNameValidator().props()).toEqual({
        namespaceFullPath: 'root',
        projectPath: 'test-name',
        projectName: 'Test Name',
      });
    });

    it('emits onValidateForm when project name validation status changes', () => {
      createComponent();

      findProjectNameInput().setValue('Test Name');
      findProjectNameInput().trigger('blur');
      findProjectSlugInput().setValue('test-name');
      findProjectSlugInput().trigger('blur');
      findProjectNameValidator().vm.$emit('onValidation', true);

      expect(wrapper.emitted('onValidateForm')[0][0]).toEqual(true);
    });

    it('emits onValidateForm with false when project name validation fails', () => {
      createComponent();
      findProjectNameValidator().vm.$emit('onValidation', false);

      expect(wrapper.emitted('onValidateForm')[0][0]).toEqual(false);
    });
  });

  describe('visibility selector', () => {
    it('renders all levels when there are no restictions and parent is public', async () => {
      createComponent();
      await nextTick();

      expect(findPrivateVisibilityLevelOption().props('disabled')).toBe(false);
      expect(findInternalVisibilityLevelOption().props('disabled')).toBe(false);
      expect(findPublicVisibilityLevelOption().props('disabled')).toBe(false);
    });

    it('renders internal visibility level as disabled when it was rescticted by admin', async () => {
      createComponent({
        provide: { restrictedVisibilityLevels: [10] },
      });
      await nextTick();

      expect(findPrivateVisibilityLevelOption().props('disabled')).toBe(false);
      expect(findInternalVisibilityLevelOption().props('disabled')).toBe(true);
      expect(findPublicVisibilityLevelOption().props('disabled')).toBe(false);
    });

    it('renders public and internal visibility levels as disabled when parent is private', async () => {
      createComponent({
        props: {
          namespace: {
            id: '1',
            fullPath: 'root',
            isPersonal: false,
            visibility: 'private',
          },
        },
      });
      await nextTick();

      expect(findPrivateVisibilityLevelOption().props('disabled')).toBe(false);
      expect(findInternalVisibilityLevelOption().props('disabled')).toBe(true);
      expect(findPublicVisibilityLevelOption().props('disabled')).toBe(true);
    });

    it('renders internal visibility level as default when admin set it up', () => {
      createComponent({
        provide: { defaultProjectVisibility: 10 },
      });

      expect(findVisibilitySelector().props('checked')).toBe(10);
    });
  });
});
