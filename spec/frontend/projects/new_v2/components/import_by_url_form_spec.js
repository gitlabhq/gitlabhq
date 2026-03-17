import { GlFormInputGroup, GlMultiStepFormTemplate } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ImportByUrlForm from '~/projects/new_v2/components/import_by_url_form.vue';
import SharedProjectCreationFields from '~/projects/new_v2/components/shared_project_creation_fields.vue';

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
    },
  };

  const createComponent = (options = {}) => {
    const { provide = {}, glFeatures = {}, mountFn = shallowMountExtended } = options;

    wrapper = mountFn(ImportByUrlForm, {
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
        SharedProjectCreationFields: true,
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
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
  const findMultiStepTemplate = () => wrapper.findComponent(GlMultiStepFormTemplate);

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('includes URL, username and password', () => {
      expect(findUrlInput().attributes('placeholder')).toBe(
        'https://gitlab.company.com/group/project.git',
      );
      expect(findUrlInput().attributes('name')).toBe('project[import_url]');
      expect(findPasswordInput().attributes('name')).toBe('project[import_url_password]');
      expect(findUsernameInput().attributes('id')).toBe('repository-username');
      expect(findMirrorCheckbox().attributes('name')).toBe('project[mirror]');
    });

    it('includes a hidden CSRF token', () => {
      const csrfInput = wrapper.find('input[name="authenticity_token"]');
      expect(csrfInput.exists()).toBe(true);
      expect(csrfInput.attributes('type')).toBe('hidden');
    });

    it('includes multi-step form template with correct props', () => {
      const template = findMultiStepTemplate();
      expect(template.props('title')).toBe('Import repository by URL');
      expect(template.props('currentStep')).toBe(3);
    });

    it('includes shared fields and passes namespace', () => {
      const sharedFields = findSharedFields();
      expect(sharedFields.exists()).toBe(true);
      expect(sharedFields.props('namespace').id).toEqual(defaultProps.namespace.id);
    });

    it('renders the option to move to Next Step', () => {
      expect(findNextButton().text()).toBe('Next step');
    });

    it('renders the next button as disabled when feature flag is off', () => {
      expect(findNextButton().props('disabled')).toBe(true);
    });

    describe('mirror repository functionality', () => {
      it('is disabled when hasRepositoryMirrorsFeature is false', () => {
        expect(findMirrorCheckbox().attributes('disabled')).not.toBeUndefined();
      });

      it('is not disabled when hasRepositoryMirrorsFeature is true', () => {
        createComponent({ provide: { hasRepositoryMirrorsFeature: true } });
        expect(findMirrorCheckbox().attributes('disabled')).toBeUndefined();
      });
    });
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

  describe('url validation on blur', () => {
    const mockUrl = 'nothing to see';

    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('validates the input when url is invalid', async () => {
      expect(findUrlInputWrapper().classes()).not.toContain('is-invalid');
      findUrlInput().vm.$emit('input', mockUrl);
      await nextTick();
      await findUrlInput().trigger('blur');
      await nextTick();
      expect(findUrlInputWrapper().classes()).toContain('is-invalid');
    });

    it('does not validate when nothing is typed', async () => {
      findUrlInput().vm.$emit('input', '');
      await nextTick();
      await findUrlInput().trigger('blur');
      await nextTick();
      expect(findUrlInputWrapper().classes()).not.toContain('is-invalid');
    });

    it('resets the invalid feedback when user refocuses and types', async () => {
      findUrlInput().vm.$emit('input', mockUrl);
      await nextTick();
      await findUrlInput().trigger('blur');
      await nextTick();
      expect(findUrlInputWrapper().classes()).toContain('is-invalid');

      await findUrlInput().vm.$emit('input', '');
      await nextTick();
      expect(findUrlInputWrapper().classes()).not.toContain('is-invalid');
    });
  });

  describe('"Check connection" functionality', () => {
    const mockUrl = 'https://example.com/repo.git';
    const mockUsername = 'mockuser';
    const mockPassword = 'mockpass';

    beforeEach(() => {
      createComponent();
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
      createComponent({ mountFn: mountExtended });
      mockAxios.onPost(mockImportByUrlValidatePath).reply(HTTP_STATUS_OK, { success: true });
      expect(findUrlInputWrapper().classes()).not.toContain('is-invalid');

      findUrlInput().vm.$emit('input', '');
      findCheckConnectionButton().vm.$emit('click');
      await nextTick();
      await waitForPromises();

      expect(mockAxios.history.post).toHaveLength(0);
      expect(findUrlInputWrapper().classes()).toContain('is-invalid');
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

  describe('emits', () => {
    beforeEach(() => {
      createComponent();
    });

    it('onSelectNamespace event when shared fields emits it', () => {
      const newNamespace = { id: '2', fullPath: 'new-namespace' };

      findSharedFields().vm.$emit('onSelectNamespace', newNamespace);

      expect(wrapper.emitted('onSelectNamespace')).toEqual([[newNamespace]]);
    });

    it(`"back" event when the back button is clicked`, () => {
      findBackButton().vm.$emit('click');
      expect(wrapper.emitted('back')).toHaveLength(1);
    });
  });
});
