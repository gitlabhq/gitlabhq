import { within } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import ProjectsField from '~/access_tokens/components/projects_field.vue';

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
    const allProjectsRadio = queryByLabelText('All projects');

    expect(allProjectsRadio).not.toBe(null);
    expect(allProjectsRadio.checked).toBe(true);
  });

  it('renders "Selected projects" radio unchecked by default', () => {
    const selectedProjectsRadio = queryByLabelText('Selected projects');

    expect(selectedProjectsRadio).not.toBe(null);
    expect(selectedProjectsRadio.checked).toBe(false);
  });

  it('renders hidden input with correct `name` and `id` attributes', () => {
    expect(wrapper.find('input[type="hidden"]').attributes()).toEqual(
      expect.objectContaining({
        id: 'projects',
        name: 'projects',
      }),
    );
  });
});
