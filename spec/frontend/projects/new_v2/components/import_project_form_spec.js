import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImportProjectForm from '~/projects/new_v2/components/import_project_form.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';
import SingleChoiceSelectorItem from '~/vue_shared/components/single_choice_selector_item.vue';

describe('Import Project Form', () => {
  let wrapper;

  const defaultProps = {
    option: {
      title: 'Import project',
    },
    namespace: {
      id: 1,
      fullPath: 'TestGroup',
      isPersonal: false,
    },
  };

  const defaultProvide = {
    importGitlabEnabled: true,
    importGithubEnabled: true,
    importGitlabImportPath: 'gitlab/import',
    importGithubImportPath: 'github/import',
  };

  const createComponent = ({ props = {}, injectedProps = {} } = {}) => {
    wrapper = shallowMountExtended(ImportProjectForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...injectedProps,
      },
    });
  };

  const findMultiStepFormTemplate = () => wrapper.findComponent(MultiStepFormTemplate);
  const findSingleChoiceSelector = () => wrapper.findComponent(SingleChoiceSelector);
  const findImportOptionItems = () => wrapper.findAllComponents(SingleChoiceSelectorItem);
  const findImportOptionItem = (index) => findImportOptionItems().at(index);
  const findNextButton = () => wrapper.findByTestId('import-project-next-button');
  const findBackButton = () => wrapper.findByTestId('import-project-back-button');

  it('passes the correct props to MultiStepFormTemplate', () => {
    createComponent();

    expect(findMultiStepFormTemplate().props()).toMatchObject({
      title: defaultProps.option.title,
      currentStep: 2,
      stepsTotal: 3,
    });
  });

  describe('next step', () => {
    it('renders the option to move to Next Step', () => {
      createComponent();

      expect(findNextButton().text()).toBe('Next step');
    });

    describe('importPath', () => {
      it(`emits the "next" event when the next button is clicked and no importPath exists`, async () => {
        createComponent({ injectedProps: { importGithubImportPath: null } });

        findSingleChoiceSelector().vm.$emit('change', 'github');

        await nextTick();

        findNextButton().vm.$emit('click');
        expect(wrapper.emitted('next')).toHaveLength(1);
      });

      it('redirects importPath when exists', async () => {
        createComponent();

        findSingleChoiceSelector().vm.$emit('change', 'github');

        await nextTick();

        expect(findNextButton().attributes('href')).toBe('github/import');
      });

      it('adds the namespaceId to the importPath for the manifest importer', async () => {
        createComponent({
          injectedProps: {
            importManifestEnabled: true,
            importManifestImportPath: 'manifest/import',
          },
        });

        findSingleChoiceSelector().vm.$emit('change', 'manifest');

        await nextTick();

        expect(findNextButton().attributes('href')).toBe('manifest/import?namespace_id=1');
      });

      it('properly converts a gid in the importPath', async () => {
        createComponent({
          provide: { namespace: { ...defaultProps.namespace, id: 'gid://gitlab/Group/1' } },
          injectedProps: {
            importManifestEnabled: true,
            importManifestImportPath: 'manifest/import',
          },
        });

        findSingleChoiceSelector().vm.$emit('change', 'manifest');

        await nextTick();

        expect(findNextButton().attributes('href')).toBe('manifest/import?namespace_id=1');
      });
    });
  });

  it(`emits the "back" event when the back button is clicked`, () => {
    createComponent();

    findBackButton().vm.$emit('click');
    expect(wrapper.emitted('back')).toHaveLength(1);
  });

  describe('available import options', () => {
    it('renders a selectable item for all available options', () => {
      createComponent();

      expect(findImportOptionItems().length).toBe(2);
      expect(findImportOptionItem(0).attributes('value')).toEqual('gitlab');
      expect(findImportOptionItem(1).attributes('value')).toEqual('github');
    });

    describe('manifest importer', () => {
      it('renders the manifest importer option when enabled', () => {
        createComponent({
          injectedProps: {
            importGitlabEnabled: false,
            importGithubEnabled: false,
            importManifestEnabled: true,
          },
        });

        expect(findImportOptionItems().length).toBe(1);
        expect(findImportOptionItem(0).attributes('value')).toEqual('manifest');
      });

      it('does not render the manifest importer for a personal namespace', () => {
        createComponent({
          props: { namespace: { ...defaultProps.namespace, isPersonal: true } },
          injectedProps: {
            importGitlabEnabled: false,
            importGithubEnabled: false,
            importManifestEnabled: true,
          },
        });

        expect(findImportOptionItems().length).toBe(0);
      });
    });
  });
});
