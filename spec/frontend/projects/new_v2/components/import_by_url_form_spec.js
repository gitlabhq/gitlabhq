import { GlFormInputGroup, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImportByUrlForm from '~/projects/new_v2/components/import_by_url_form.vue';
import SharedProjectCreationFields from '~/projects/new_v2/components/shared_project_creation_fields.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const $toast = {
  show: jest.fn(),
};

describe('Import Project by URL Form', () => {
  let wrapper;
  let mockAxios;

  const mockImportByUrlValidatePath = '/import/url/validate';
  const mockNewProjectPath = '/projects/new';
  const mockNewProjectFormPath = '/projects';
  const defaultProps = {
    namespace: {
      id: '1',
      fullPath: 'root',
      isPersonal: true,
    },
  };

  const createComponent = (options = {}) => {
    const { provide = {}, glFeatures = {} } = options;

    wrapper = shallowMountExtended(ImportByUrlForm, {
      provide: {
        importByUrlValidatePath: mockImportByUrlValidatePath,
        newProjectPath: mockNewProjectPath,
        newProjectFormPath: mockNewProjectFormPath,
        hasRepositoryMirrorsFeature: false,
        glFeatures: {
          importByUrlNewPage: false,
          ...glFeatures,
        },
        ...provide,
      },
      propsData: defaultProps,
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

  const findNextButton = () => wrapper.findByTestId('import-project-by-url-next-button');
  const findBackButton = () => wrapper.findByTestId('import-project-by-url-back-button');
  const findUrlInput = () => wrapper.findByTestId('repository-url');
  const findUrlInputWrapper = () => wrapper.findByTestId('repository-url-form-group');
  const findUsernameInput = () => wrapper.findByTestId('repository-username');
  const findPasswordInput = () => wrapper.findByTestId('repository-password');
  const findCheckConnectionButton = () => wrapper.findByTestId('check-connection');
  const findMirrorCheckbox = () => wrapper.findByTestId('import-project-by-url-repo-mirror');
  const findSharedFields = () => wrapper.findComponent(SharedProjectCreationFields);
  const findMultiStepTemplate = () => wrapper.findComponent(MultiStepFormTemplate);

  it('renders URL, username, password fields', () => {
    expect(findUrlInput().attributes('placeholder')).toBe(
      'https://gitlab.company.com/group/project.git',
    );
    expect(findUrlInput().attributes('name')).toBe('project[import_url]');
    expect(findPasswordInput().attributes('name')).toBe('project[import_url_password]');
    expect(findUsernameInput().attributes('id')).toBe('repository-username');
    expect(findMirrorCheckbox().attributes('name')).toBe('project[mirror]');
  });

  it('includes a hidden CSRF token in form', () => {
    const csrfInput = wrapper.find('input[name="authenticity_token"]');
    expect(csrfInput.exists()).toBe(true);
    expect(csrfInput.attributes('type')).toBe('hidden');
  });

  it('renders multi-step form template with correct props', () => {
    const template = findMultiStepTemplate();
    expect(template.props('title')).toBe('Import repository by URL');
    expect(template.props('currentStep')).toBe(3);
  });

  it('renders shared fields', () => {
    const sharedFields = findSharedFields();
    expect(sharedFields.exists()).toBe(true);
    expect(sharedFields.props('namespace')).toEqual(defaultProps.namespace);
  });

  describe('when importByUrlNewPage feature flag is enabled', () => {
    beforeEach(() => {
      createComponent({ glFeatures: { importByUrlNewPage: true } });
    });

    it('sets currentStep to null', () => {
      const template = findMultiStepTemplate();
      expect(template.props('currentStep')).toBe(null);
    });

    it('renders "Create project" button instead of "Next step"', () => {
      const nextButton = findNextButton();
      expect(nextButton.text()).toBe('Create project');
      expect(nextButton.attributes('type')).toBe('submit');
    });

    it('navigates to `new project` page when back button is clicked', () => {
      findBackButton().vm.$emit('click');
      expect(visitUrl).toHaveBeenCalledWith(mockNewProjectPath);
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

  it('emits onSelectNamespace event when shared fields emits it', () => {
    const newNamespace = { id: '2', fullPath: 'new-namespace', isPersonal: false };

    findSharedFields().vm.$emit('onSelectNamespace', newNamespace);

    expect(wrapper.emitted('onSelectNamespace')).toEqual([[newNamespace]]);
  });

  it('renders the option to move to Next Step', () => {
    expect(findNextButton().text()).toBe('Next step');
  });

  it('renders the next button as disabled when feature flag is off', () => {
    expect(findNextButton().props('disabled')).toBe(true);
  });

  it(`emits the "back" event when the back button is clicked`, () => {
    findBackButton().vm.$emit('click');
    expect(wrapper.emitted('back')).toHaveLength(1);
  });

  describe('mirror repository functionality', () => {
    it('is rendered disabled when hasRepositoryMirrorsFeature is false', () => {
      expect(findMirrorCheckbox().attributes('disabled')).not.toBeUndefined();
    });

    it('is not disabled when hasRepositoryMirrorsFeature is true', () => {
      createComponent({ provide: { hasRepositoryMirrorsFeature: true } });
      expect(findMirrorCheckbox().attributes('disabled')).toBeUndefined();
    });
  });
});
