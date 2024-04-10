import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/projects/edit/components/app.vue';
import NewEditForm from '~/projects/components/new_edit_form.vue';

describe('OrganizationProjectsEditApp', () => {
  let wrapper;

  const defaultProvide = {
    project: {
      id: 1,
      name: 'Foo bar',
      fullName: 'Mock namespace / Foo bar',
      description: 'Mock description',
    },
    projectsOrganizationPath: '/-/organizations/default/groups_and_projects?display=projects',
    previewMarkdownPath: '/-/organizations/preview_markdown',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(App, {
      provide: defaultProvide,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findForm = () => wrapper.findComponent(NewEditForm);

  it('renders page title', () => {
    createComponent();

    expect(
      wrapper.findByRole('heading', { name: 'Edit project: Mock namespace / Foo bar' }).exists(),
    ).toBe(true);
  });

  it('renders form and passes expected props', () => {
    createComponent();

    expect(findForm().props()).toMatchObject({
      loading: false,
      initialFormValues: defaultProvide.project,
      previewMarkdownPath: defaultProvide.previewMarkdownPath,
      cancelButtonHref: defaultProvide.projectsOrganizationPath,
    });
  });
});
