import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getLocationHash, setLocationHash } from '~/lib/utils/url_utility';
import App from '~/projects/new_v2/components/app.vue';
import FormBreadcrumb from '~/projects/new_v2/components/form_breadcrumb.vue';
import CommandLine from '~/projects/new_v2/components/command_line.vue';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';
import ImportByUrlForm from '~/projects/new_v2/components/import_by_url_form.vue';

jest.mock('~/lib/utils/url_utility');

describe('New project creation app', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(App, {
      provide: {
        userNamespaceId: '1',
        userNamespaceFullPath: 'root',
        canCreateProject: true,
        projectsUrl: '/dashboard/projects',
        userProjectLimit: 10000,
        canSelectNamespace: true,
        isCiCdAvailable: true,
        canImportProjects: true,
        importSourcesEnabled: true,
        ...provide,
      },
      stubs: {
        Component: { template: '<div></div>', props: ['option'] },
      },
    });
  };

  const findStep1 = () => wrapper.findByTestId('new-project-step1');
  const findBreadcrumbs = () => wrapper.findComponent(FormBreadcrumb);
  const findSingleChoiceSelector = () => wrapper.findComponent(SingleChoiceSelector);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCommandLine = () => wrapper.findComponent(CommandLine);
  const findNextButton = () => wrapper.findByTestId('new-project-next');
  const findStep2 = () => wrapper.findByTestId('new-project-step2');
  const findImportByUrlForm = () => wrapper.findComponent(ImportByUrlForm);

  it('renders breadcrumbs', () => {
    createComponent();

    expect(findBreadcrumbs().exists()).toBe(true);
  });

  it('renders step 1 form', () => {
    createComponent();

    expect(findStep1().exists()).toBe(true);
    expect(findAlert().exists()).toBe(false);
  });

  it('does not render step 2', () => {
    createComponent();

    expect(findStep2().exists()).toBe(false);
  });

  it('uses blank_project as default projectType', () => {
    createComponent();

    expect(findSingleChoiceSelector().props('checked')).toBe('blank_project');
  });

  describe('when location hash is present', () => {
    afterEach(() => {
      getLocationHash.mockReset();
    });

    describe('and is valid projectType', () => {
      beforeEach(() => {
        getLocationHash.mockReturnValue('cicd_for_external_repo');

        createComponent({ isCiCdAvailable: true });
      });

      it('renders step 2 component from hash', () => {
        expect(findStep2().exists()).toBe(true);
        expect(findStep2().props('option').value).toBe('cicd_for_external_repo');
      });
    });

    describe('and is invalid projectType', () => {
      beforeEach(() => {
        getLocationHash.mockReturnValue('nonexistent');

        createComponent();
      });

      it('renders step 1', () => {
        expect(findStep1().exists()).toBe(true);
      });
    });
  });

  describe('personal namespace project', () => {
    it('starts with personal namespace when no namespaceId provided', () => {
      createComponent();

      expect(wrapper.findByTestId('personal-namespace-button').props('selected')).toBe(true);
      expect(wrapper.findByTestId('group-namespace-button').props('selected')).toBe(false);
    });

    it('does not renders a group select', () => {
      createComponent();

      expect(wrapper.findByTestId('group-selector').exists()).toBe(false);
    });

    it('renders error when user reached a limit of projects', () => {
      createComponent({ canCreateProject: false });

      expect(findSingleChoiceSelector().exists()).toBe(false);
      expect(findAlert().text()).toBe(
        "You've reached your limit of 10,000 projects created. Contact your GitLab administrator.",
      );
    });

    it('renders error when user can not create personal projects', () => {
      createComponent({ userProjectLimit: 0, canCreateProject: false });

      expect(findSingleChoiceSelector().exists()).toBe(false);
      expect(findAlert().text()).toBe(
        'You cannot create projects in your personal namespace. Contact your GitLab administrator.',
      );
    });
  });

  describe('group namespace project', () => {
    it('starts with group namespace when namespaceId provided', () => {
      createComponent({ namespaceId: '2' });

      expect(wrapper.findByTestId('personal-namespace-button').props('selected')).toBe(false);
      expect(wrapper.findByTestId('group-namespace-button').props('selected')).toBe(true);
    });

    it('renders a group select', () => {
      createComponent({ namespaceId: '2' });

      expect(wrapper.findByTestId('group-selector').exists()).toBe(true);
    });

    it('renders error when user click next button with no namespace provided', async () => {
      createComponent();

      wrapper.findByTestId('group-namespace-button').vm.$emit('click');
      findNextButton().trigger('click');
      await nextTick();

      const formGroup = wrapper.findByTestId('group-selector-form-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe(
        'Pick a group or namespace where you want to create this project.',
      );
    });
  });

  describe('with command line', () => {
    it('renders for a personal namespace', () => {
      createComponent();

      expect(findCommandLine().exists()).toBe(true);
    });

    it('does not renders for a group namespace', () => {
      createComponent({ namespaceId: '13' });

      expect(findCommandLine().exists()).toBe(false);
    });
  });

  describe('when projectType is changed', () => {
    beforeEach(() => {
      createComponent();

      findSingleChoiceSelector().vm.$emit('change', 'create_from_template');
    });

    it('updates the selected projectType', () => {
      expect(findSingleChoiceSelector().props('checked')).toBe('create_from_template');
    });

    describe('and "Next" button is clicked', () => {
      beforeEach(() => {
        findNextButton().vm.$emit('click');
      });

      it('hides step 1', () => {
        expect(findStep1().exists()).toBe(false);
      });

      it('shows step 2 component', () => {
        expect(findStep2().exists()).toBe(true);
        expect(findStep2().props('option').value).toBe('create_from_template');
      });

      it('updates location hash', () => {
        expect(setLocationHash).toHaveBeenLastCalledWith('create_from_template');
      });

      describe('and "Back" event is emitted from step 2', () => {
        beforeEach(() => {
          findStep2().vm.$emit('back');
        });

        it('shows step 1', () => {
          expect(findStep1().exists()).toBe(true);
        });

        it('hides step 2 component', () => {
          expect(findStep2().exists()).toBe(false);
        });

        it('removes location hash', () => {
          expect(setLocationHash).toHaveBeenLastCalledWith();
        });
      });
    });
  });

  describe('import by URL form', () => {
    beforeEach(async () => {
      createComponent();

      findSingleChoiceSelector().vm.$emit('change', 'import_project');

      findNextButton().vm.$emit('click');
      await waitForPromises(); // wait for the dynamic component to be rendered
      findStep2().vm.$emit('next');
    });

    it('renders import by URL form', () => {
      expect(findImportByUrlForm().props('namespace')).toEqual({
        id: '1',
        fullPath: 'root',
        isPersonal: true,
      });
    });

    it('emits back event when import by URL form emits back', async () => {
      findImportByUrlForm().vm.$emit('back');
      await nextTick();

      expect(findStep2().exists()).toBe(true);
      expect(findImportByUrlForm().exists()).toBe(false);
    });
  });
});
