import { within, fireEvent } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import ProjectsField from '~/access_tokens/components/projects_field.vue';
import ProjectsTokenSelector from '~/access_tokens/components/projects_token_selector.vue';

describe('ProjectsField', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(ProjectsField, {
      propsData: {
        inputAttrs: {
          id: 'projects',
          name: 'projects',
        },
      },
    });
  };

  const queryByLabelText = (text) => within(wrapper.element).queryByLabelText(text);
  const queryByText = (text) => within(wrapper.element).queryByText(text);
  const findAllProjectsRadio = () => queryByLabelText('All projects');
  const findSelectedProjectsRadio = () => queryByLabelText('Selected projects');
  const findProjectsTokenSelector = () => wrapper.findComponent(ProjectsTokenSelector);
  const findHiddenInput = () => wrapper.find('input[type="hidden"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders label and sub-label', () => {
    expect(queryByText('Projects')).not.toBe(null);
    expect(queryByText('Set access permissions for this token.')).not.toBe(null);
  });

  it('renders "All projects" radio selected by default', () => {
    const allProjectsRadio = findAllProjectsRadio();

    expect(allProjectsRadio).not.toBe(null);
    expect(allProjectsRadio.checked).toBe(true);
  });

  it('renders "Selected projects" radio unchecked by default', () => {
    const selectedProjectsRadio = findSelectedProjectsRadio();

    expect(selectedProjectsRadio).not.toBe(null);
    expect(selectedProjectsRadio.checked).toBe(false);
  });

  it('renders `projects-token-selector` component', () => {
    expect(findProjectsTokenSelector().exists()).toBe(true);
  });

  it('renders hidden input with correct `name` and `id` attributes', () => {
    expect(findHiddenInput().attributes()).toEqual(
      expect.objectContaining({
        id: 'projects',
        name: 'projects',
      }),
    );
  });

  describe('when `projects-token-selector` is focused', () => {
    beforeEach(() => {
      findProjectsTokenSelector().vm.$emit('focus');
    });

    it('auto selects the "Selected projects" radio', () => {
      expect(findSelectedProjectsRadio().checked).toBe(true);
    });

    describe('when `projects-token-selector` is changed', () => {
      beforeEach(() => {
        findProjectsTokenSelector().vm.$emit('input', [
          {
            id: 1,
          },
          {
            id: 2,
          },
        ]);
      });

      it('updates the hidden input value to a comma separated list of project IDs', () => {
        expect(findHiddenInput().attributes('value')).toBe('1,2');
      });

      describe('when radio is changed back to "All projects"', () => {
        beforeEach(() => {
          fireEvent.click(findAllProjectsRadio());
        });

        it('removes the hidden input value', () => {
          expect(findHiddenInput().attributes('value')).toBe('');
        });
      });
    });
  });
});
