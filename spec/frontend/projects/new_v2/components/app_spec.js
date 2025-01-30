import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/projects/new_v2/components/app.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

describe('New project creation app', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        rootPath: '/',
        projectsUrl: '/dashboard/projects',
        userNamespaceId: '1',
        ...props,
      },
    });
  };

  const findMultyStepForm = () => wrapper.findComponent(MultiStepFormTemplate);

  it('renders a form', () => {
    createComponent();

    expect(findMultyStepForm().exists()).toBe(true);
  });

  describe('personal namespace project', () => {
    beforeEach(() => {
      createComponent();
    });

    it('starts with personal namespace when no namespaceId provided', () => {
      expect(wrapper.findByTestId('personal-namespace-button').props('selected')).toBe(true);
      expect(wrapper.findByTestId('group-namespace-button').props('selected')).toBe(false);
    });

    it('does not renders a group select', () => {
      expect(wrapper.findByTestId('group-selector').exists()).toBe(false);
    });
  });
});
