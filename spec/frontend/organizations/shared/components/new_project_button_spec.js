import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NewProjectButton from '~/organizations/shared/components/new_project_button.vue';

describe('NewProjectButton', () => {
  let wrapper;

  const defaultProvide = {
    canCreateProject: false,
    newProjectPath: '',
    hasGroups: false,
  };

  function createComponent({ provide = {} } = {}) {
    wrapper = shallowMountExtended(NewProjectButton, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  }

  const findTooltipContainer = () => wrapper.findByTestId('new-project-button-tooltip-container');
  const findGlButton = () => wrapper.findComponent(GlButton);

  describe.each`
    canCreateProject | newProjectPath
    ${false}         | ${null}
    ${false}         | ${'/asdf'}
    ${true}          | ${null}
  `(
    'when `canCreateProject` is $canCreateProject and `newProjectPath` is $newProjectPath',
    ({ canCreateProject, newProjectPath }) => {
      beforeEach(() => {
        createComponent({ provide: { canCreateProject, newProjectPath } });
      });

      it('renders nothing', () => {
        expect(wrapper.find('*').exists()).toBe(false);
      });
    },
  );

  describe('when `canCreateProject` is true and `newProjectPath` is /asdf', () => {
    const newProjectPath = '/asdf';

    beforeEach(() => {
      createComponent({ provide: { canCreateProject: true, newProjectPath } });
    });

    it('renders GlButton correctly', () => {
      expect(findGlButton().attributes('href')).toBe(newProjectPath);
    });
  });

  describe.each`
    hasGroups | disabled     | tooltip
    ${false}  | ${'true'}    | ${'Projects are hosted/created in groups. Before creating a project, you must create a group.'}
    ${true}   | ${undefined} | ${undefined}
  `(
    'when `canCreateProject` is true , `newProjectPath` is /asdf, and hasGroups is $hasGroups',
    ({ hasGroups, disabled, tooltip }) => {
      beforeEach(() => {
        createComponent({
          provide: { canCreateProject: true, newProjectPath: '/asdf', hasGroups },
        });
      });

      it(`renders GlButton as ${disabled ? 'disabled' : 'not disabled'} with ${
        tooltip ? 'tooltip' : 'no tooltip'
      }`, () => {
        expect(findGlButton().attributes().disabled).toBe(disabled);
        expect(findTooltipContainer().attributes('title')).toBe(tooltip);
      });
    },
  );
});
