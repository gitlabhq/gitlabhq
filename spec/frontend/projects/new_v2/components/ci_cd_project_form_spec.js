import { GlFormInputGroup, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CICDProjectForm from '~/projects/new_v2/components/ci_cd_project_form.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SharedProjectCreationFields from '~/projects/new_v2/components/shared_project_creation_fields.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const $toast = {
  show: jest.fn(),
};

describe('CI/CD Project Form', () => {
  let wrapper;
  let mockAxios;

  const defaultProps = {
    option: {
      title: 'Import project',
    },
    namespace: {
      id: '1',
      fullPath: 'root',
      isPersonal: true,
    },
  };
  const mockImportByUrlValidatePath = '/import/url/validate';
  const mockNewProjectFormPath = '/projects';
  const mockConnectGitHubPath = '/import/github/new';

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(CICDProjectForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        formPath: mockNewProjectFormPath,
        importByUrlValidatePath: mockImportByUrlValidatePath,
        importGithubImportPath: mockConnectGitHubPath,
        ...provide,
      },
      mocks: {
        $toast,
      },
      stubs: {
        GlFormInputGroup,
        GlFormCheckbox,
        MultiStepFormTemplate,
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    mockAxios.restore();
  });

  const findForm = () => wrapper.find('form');
  const findMultiStepFormTemplate = () => wrapper.findComponent(MultiStepFormTemplate);
  const findSharedProjectCreationFields = () => wrapper.findComponent(SharedProjectCreationFields);
  const findUrlInput = () => wrapper.findByTestId('repository-url');
  const findUrlInputWrapper = () => wrapper.findByTestId('repository-url-form-group');
  const findUsernameInput = () => wrapper.findByTestId('repository-username');
  const findPasswordInput = () => wrapper.findByTestId('repository-password');
  const findCheckConnectionButton = () => wrapper.findByTestId('check-connection');
  const findGitHubButton = () => wrapper.findByTestId('connect-github-project-button');
  const findBackButton = () => wrapper.findByTestId('create-cicd-project-back-button');

  it('passes the correct props to MultiStepFormTemplate', () => {
    expect(findMultiStepFormTemplate().props()).toMatchObject({
      title: defaultProps.option.title,
      currentStep: 2,
      stepsTotal: 2,
    });
  });

  describe('form', () => {
    it('renders the SharedProjectCreationFields component', () => {
      expect(findSharedProjectCreationFields().exists()).toBe(true);
      expect(findSharedProjectCreationFields().props('namespace')).toEqual(defaultProps.namespace);
    });

    it('renders URL, username, password fields', () => {
      expect(findUrlInput().attributes('placeholder')).toBe(
        'https://gitlab.company.com/group/project.git',
      );
      expect(findUrlInput().attributes('name')).toBe('project[import_url]');
      expect(findPasswordInput().attributes('name')).toBe('project[import_url_password]');
      expect(findUsernameInput().attributes('id')).toBe('repository-username');
    });

    it('renders the form element correctly', () => {
      const form = findForm();

      expect(form.attributes('action')).toBe('/projects');
      expect(form.find('input[type=hidden][name=authenticity_token]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('does not submit the form without required fields', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      findSharedProjectCreationFields().vm.$emit('onValidateForm', false);

      findForm().trigger('submit');
      expect(submitSpy).not.toHaveBeenCalled();
    });

    it('submit the form correctly', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      findSharedProjectCreationFields().vm.$emit('onValidateForm', true);

      findForm().trigger('submit');
      expect(submitSpy).toHaveBeenCalled();
    });
  });

  describe('"Check connection" functionality', () => {
    const mockUrl = 'https://example.com/repo.git';
    const mockUsername = 'mockuser';
    const mockPassword = 'mockpass';

    beforeEach(() => {
      findUrlInput().vm.$emit('input', mockUrl);
      findUsernameInput().vm.$emit('input', mockUsername);
      findPasswordInput().vm.$emit('input', mockPassword);
    });

    it('shows loading state during connection check', async () => {
      mockAxios.onPost(mockImportByUrlValidatePath).reply(HTTP_STATUS_OK, { success: true });

      expect(findCheckConnectionButton().props('loading')).toBe(false);

      findCheckConnectionButton().vm.$emit('click');
      await nextTick();

      expect(findCheckConnectionButton().props('loading')).toBe(true);

      await waitForPromises();

      expect(findCheckConnectionButton().props('loading')).toBe(false);
    });

    it('prevents connection if url field is empty', async () => {
      mockAxios.onPost(mockImportByUrlValidatePath).reply(HTTP_STATUS_OK, { success: true });

      findUrlInput().vm.$emit('input', '');

      findCheckConnectionButton().vm.$emit('click');
      await waitForPromises();

      expect(mockAxios.history.post).toHaveLength(0);
      expect(findUrlInputWrapper().attributes('invalid-feedback')).toBe('Enter a valid URL');
    });

    describe('when connection is successful', () => {
      beforeEach(async () => {
        mockAxios.onPost(mockImportByUrlValidatePath).reply(HTTP_STATUS_OK, { success: true });

        findCheckConnectionButton().vm.$emit('click');
        await waitForPromises();
      });

      it('sends correct request', () => {
        expect(mockAxios.history.post[0].data).toBe(
          JSON.stringify({
            url: mockUrl,
            user: mockUsername,
            password: mockPassword,
          }),
        );
      });

      it('shows success message when connection is successful', () => {
        expect($toast.show).toHaveBeenCalledWith('Connection successful.');
      });
    });

    describe('when connection fails', () => {
      it('shows error message', async () => {
        const errorMessage = 'Invalid credentials';
        mockAxios
          .onPost(mockImportByUrlValidatePath)
          .reply(HTTP_STATUS_OK, { success: false, message: errorMessage });
        findCheckConnectionButton().vm.$emit('click');

        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith(`Connection failed: ${errorMessage}`);
      });
    });

    describe('when request fails', () => {
      it('shows error message', async () => {
        mockAxios.onPost(mockImportByUrlValidatePath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        findCheckConnectionButton().vm.$emit('click');

        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith(expect.stringContaining('Connection failed'));
      });
    });
  });

  it('renders "Connect repositories from GitHub" button correctly', () => {
    expect(findGitHubButton().exists()).toBe(true);
    expect(findGitHubButton().props('href')).toEqual(mockConnectGitHubPath);
  });

  it(`emits the "back" event when the back button is clicked`, () => {
    findBackButton().vm.$emit('click');
    expect(wrapper.emitted('back')).toHaveLength(1);
  });
});
