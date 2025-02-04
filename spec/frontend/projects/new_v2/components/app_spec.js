import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/projects/new_v2/components/app.vue';
import FormBreadcrumb from '~/projects/new_v2/components/form_breadcrumb.vue';
import CommandLine from '~/projects/new_v2/components/command_line.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';

describe('New project creation app', () => {
  let wrapper;

  const createComponent = (props = {}, provide = {}) => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        rootPath: '/',
        projectsUrl: '/dashboard/projects',
        userProjectLimit: 10000,
        canSelectNamespace: true,
        ...props,
      },
      provide: {
        userNamespaceId: '1',
        canCreateProject: true,
        ...provide,
      },
    });
  };

  const findMultiStepForm = () => wrapper.findComponent(MultiStepFormTemplate);
  const findBreadcrumbs = () => wrapper.findComponent(FormBreadcrumb);
  const findSingleChoiceSelector = () => wrapper.findComponent(SingleChoiceSelector);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCommandLine = () => wrapper.findComponent(CommandLine);

  it('renders breadcrumbs', () => {
    createComponent();

    expect(findBreadcrumbs().exists()).toBe(true);
  });

  it('renders a form', () => {
    createComponent();

    expect(findMultiStepForm().exists()).toBe(true);
    expect(findAlert().exists()).toBe(false);
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
      createComponent({}, { canCreateProject: false });

      expect(findSingleChoiceSelector().exists()).toBe(false);
      expect(findAlert().text()).toBe(
        "You've reached your limit of 10000 projects created. Contact your GitLab administrator.",
      );
    });

    it('renders error when user can not create personal projects', () => {
      createComponent({ userProjectLimit: 0 }, { canCreateProject: false });

      expect(findSingleChoiceSelector().exists()).toBe(false);
      expect(findAlert().text()).toBe(
        'You cannot create projects in your personal namespace. Contact your GitLab administrator.',
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
});
