import { within, fireEvent } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import ProjectsField from '~/access_tokens/components/projects_field.vue';
import ProjectsTokenSelector from '~/access_tokens/components/projects_token_selector.vue';

describe('ProjectsField', () => {
  let wrapper;

  const createComponent = ({ inputAttrsValue = '' } = {}) => {
    wrapper = mount(ProjectsField, {
      propsData: {
        inputAttrs: {
          id: 'projects',
          name: 'projects',
          value: inputAttrsValue,
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders label and sub-label', () => {
    createComponent();

    expect(queryByText('Projects')).not.toBe(null);
    expect(queryByText('Set access permissions for this token.')).not.toBe(null);
  });

  describe('when `inputAttrs.value` is empty', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders "All projects" radio as checked', () => {
      expect(findAllProjectsRadio().checked).toBe(true);
    });

    it('renders "Selected projects" radio as unchecked', () => {
      expect(findSelectedProjectsRadio().checked).toBe(false);
    });

    it('sets `projects-token-selector` `initialProjectIds` prop to an empty array', () => {
      expect(findProjectsTokenSelector().props('initialProjectIds')).toEqual([]);
    });
  });

  describe('when `inputAttrs.value` is a comma separated list of project IDs', () => {
    beforeEach(() => {
      createComponent({ inputAttrsValue: '1,2' });
    });

    it('renders "All projects" radio as unchecked', () => {
      expect(findAllProjectsRadio().checked).toBe(false);
    });

    it('renders "Selected projects" radio as checked', () => {
      expect(findSelectedProjectsRadio().checked).toBe(true);
    });

    it('sets `projects-token-selector` `initialProjectIds` prop to an array of project IDs', () => {
      expect(findProjectsTokenSelector().props('initialProjectIds')).toEqual(['1', '2']);
    });
  });

  it('renders `projects-token-selector` component', () => {
    createComponent();

    expect(findProjectsTokenSelector().exists()).toBe(true);
  });

  it('renders hidden input with correct `name` and `id` attributes', () => {
    createComponent();

    expect(findHiddenInput().attributes()).toEqual(
      expect.objectContaining({
        id: 'projects',
        name: 'projects',
      }),
    );
  });

  describe('when `projects-token-selector` is focused', () => {
    beforeEach(() => {
      createComponent();

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
