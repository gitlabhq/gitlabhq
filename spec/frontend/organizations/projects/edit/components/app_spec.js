import { nextTick } from 'vue';
import { GlSprintf } from '@gitlab/ui';
import project from 'test_fixtures/api/projects/put.json';
import projectValidationError from 'test_fixtures/api/projects/put_validation_error.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/projects/edit/components/app.vue';
import NewEditForm from '~/projects/components/new_edit_form.vue';
import { updateProject } from '~/api/projects_api';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { FORM_FIELD_NAME, FORM_FIELD_DESCRIPTION } from '~/projects/components/constants';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

jest.mock('~/api/projects_api');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

useMockLocationHelper();

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

  const submitForm = async () => {
    findForm().vm.$emit('submit', {
      name: 'Foo bar updated',
      description: 'Mock description updated',
    });
    await nextTick();
  };

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

  describe('when form is submitted', () => {
    describe('when API is loading', () => {
      beforeEach(async () => {
        updateProject.mockResolvedValueOnce({ data: project });
        createComponent();

        await submitForm();
      });

      it('sets `NewEditForm` `loading` prop to `true`', () => {
        expect(findForm().props('loading')).toBe(true);
      });
    });

    describe('when API request is successful', () => {
      beforeEach(async () => {
        updateProject.mockResolvedValueOnce({ data: project });
        createComponent();
        await submitForm();
        await waitForPromises();
      });

      it('calls API with correct variables and reloads the page with success alert', () => {
        expect(updateProject).toHaveBeenCalledWith(defaultProvide.project.id, {
          name: 'Foo bar updated',
          description: 'Mock description updated',
        });
        expect(visitUrlWithAlerts).toHaveBeenCalledWith(window.location.href, [
          {
            id: 'organization-project-successfully-updated',
            message: 'Project was successfully updated.',
            variant: 'info',
          },
        ]);
      });
    });

    describe('when API request is not successful', () => {
      describe('when error is a server error', () => {
        const error = new Error();

        beforeEach(async () => {
          updateProject.mockRejectedValueOnce(error);
          createComponent();
          await submitForm();
          await waitForPromises();
        });

        it('displays error alert', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred updating this project. Please try again.',
            error,
            captureError: true,
          });
        });

        it('sets `loading` prop to `false`', () => {
          expect(findForm().props('loading')).toBe(false);
        });
      });

      describe('when error is a validation error', () => {
        const error = { response: { data: projectValidationError } };

        beforeEach(async () => {
          updateProject.mockRejectedValueOnce(error);
          createComponent();
          await submitForm();
          await waitForPromises();
        });

        it('sets `loading` prop to `false`', () => {
          expect(findForm().props('loading')).toBe(false);
        });

        it('shows validation error for `Project name` field', () => {
          expect(findForm().props('serverValidations')).toMatchObject({
            [FORM_FIELD_NAME]:
              "Project name can contain only letters, digits, emoji, '_', '.', '+', dashes, or spaces. It must start with a letter, digit, emoji, or '_'.",
          });
        });

        it('shows validation error for `Project description` field', () => {
          expect(findForm().props('serverValidations')).toMatchObject({
            [FORM_FIELD_DESCRIPTION]:
              'Project description is too long (maximum is 2000 characters)',
          });
        });

        describe('when `input-field` event is fired', () => {
          beforeEach(() => {
            findForm().vm.$emit('input-field', { name: FORM_FIELD_NAME, value: 'foo' });
          });

          it('clears server validation for that field', () => {
            expect(findForm().props('serverValidations')[FORM_FIELD_NAME]).toBeUndefined();
          });
        });
      });
    });
  });
});
