import { GlFormInputGroup, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ImportByUrlToExistingProjectForm from '~/projects/new_v2/components/import_by_url_to_existing_project_form.vue';

const $toast = {
  show: jest.fn(),
};

describe('ImportByUrlToExistingProjectForm', () => {
  let wrapper;
  let mockAxios;

  const mockImportByUrlValidatePath = '/import/url/validate';
  const mockImportPath = '/group/myproject';
  const mockGitTimeout = '10 minutes';
  const previouslyFailedGitURL = 'https://gita.git';

  const createComponent = (mountFn = shallowMountExtended, options = {}) => {
    const { provide = {} } = options;

    wrapper = mountFn(ImportByUrlToExistingProjectForm, {
      provide: {
        importByUrlValidatePath: mockImportByUrlValidatePath,
        importPath: mockImportPath,
        gitTimeout: mockGitTimeout,
        ciCdOnly: false,
        importFromUrl: previouslyFailedGitURL,
        hasRepositoryMirrorsFeature: false,
        ...provide,
      },
      mocks: {
        $toast,
      },
      stubs: {
        GlFormInputGroup,
        GlFormCheckbox,
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  const findUrlInput = () => wrapper.findByTestId('project_import_url');
  const findUrlInputWrapper = () => wrapper.findByTestId('repository-url-form-group');
  const findUsernameInput = () => wrapper.findByTestId('repository-username');
  const findPasswordInput = () => wrapper.findByTestId('repository-password');
  const findCheckConnectionButton = () => wrapper.findByTestId('check-connection');
  const findMirrorCheckbox = () => wrapper.findByTestId('import-project-by-url-repo-mirror');

  const triggerConnectionCheck = () => {
    findCheckConnectionButton().vm.$emit('click');
    return waitForPromises();
  };

  it('renders URL, username, password fields', () => {
    createComponent();
    expect(findUrlInput().attributes('placeholder')).toBe(
      'https://gitlab.company.com/group/project.git',
    );
    expect(findUrlInput().attributes('name')).toBe('project[import_url]');
    expect(findPasswordInput().attributes('name')).toBe('project[import_url_password]');
    expect(findUsernameInput().attributes('id')).toBe('repository-username');
    expect(findMirrorCheckbox().attributes('name')).toBe('project[mirror]');
  });

  it('includes a hidden CSRF token in form', () => {
    createComponent();
    const csrfInput = wrapper.find('input[name="authenticity_token"]');
    expect(csrfInput.exists()).toBe(true);
    expect(csrfInput.attributes('type')).toBe('hidden');
  });

  it('renders the failed url in the url input', () => {
    createComponent();
    expect(findUrlInput().attributes('value')).toBe(previouslyFailedGitURL);
  });

  describe('url input validation', () => {
    beforeEach(() => {
      createComponent(mountExtended);
    });

    it('prevents POST connection if url field is empty', async () => {
      mockAxios.onPost(mockImportByUrlValidatePath).reply(HTTP_STATUS_OK, { success: true });

      findUrlInput().vm.$emit('input', '');

      await triggerConnectionCheck();

      expect(mockAxios.history.post).toHaveLength(0);
    });

    it('validates input on blur', async () => {
      expect(findUrlInputWrapper().classes()).not.toContain('is-invalid');
      findUrlInput().vm.$emit('input', 'blah blah');
      await nextTick();
      await findUrlInput().trigger('blur');
      await nextTick();
      expect(findUrlInputWrapper().classes()).toContain('is-invalid');
      expect(findUrlInputWrapper().text()).toContain('Enter a valid URL'); // this is always in DOM
    });
  });

  describe('"Check connection" functionality', () => {
    const mockUrl = 'https://example.com/repo.git';
    const mockUsername = 'mockuser';
    const mockPassword = 'mockpass';

    beforeEach(() => {
      createComponent();
    });

    it('shows loading state during connection check', async () => {
      findUrlInput().vm.$emit('input', mockUrl);
      mockAxios.onPost(mockImportByUrlValidatePath).reply(HTTP_STATUS_OK, { success: true });

      expect(findCheckConnectionButton().props('loading')).toBe(false);

      findCheckConnectionButton().vm.$emit('click');
      await nextTick();

      expect(findCheckConnectionButton().props('loading')).toBe(true);

      await waitForPromises();

      expect(findCheckConnectionButton().props('loading')).toBe(false);
    });

    describe('when connection is successful', () => {
      beforeEach(async () => {
        mockAxios.onPost(mockImportByUrlValidatePath).reply(HTTP_STATUS_OK, { success: true });
        findUrlInput().vm.$emit('input', mockUrl);
        findUsernameInput().vm.$emit('input', mockUsername);
        findPasswordInput().vm.$emit('input', mockPassword);
        await waitForPromises();
        await triggerConnectionCheck();
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
        findUrlInput().vm.$emit('input', mockUrl);
        const errorMessage = 'Host cannot be resolved or invalid';
        mockAxios
          .onPost(mockImportByUrlValidatePath)
          .reply(HTTP_STATUS_OK, { success: false, message: errorMessage });
        await triggerConnectionCheck();

        expect($toast.show).toHaveBeenCalledWith(`Connection failed: ${errorMessage}`);
      });
    });
  });

  describe('mirror repository functionality', () => {
    it('is rendered disabled when hasRepositoryMirrorsFeature is false', () => {
      createComponent();
      expect(findMirrorCheckbox().attributes('disabled')).not.toBeUndefined();
    });

    it('is not disabled when hasRepositoryMirrorsFeature is true', () => {
      createComponent(shallowMountExtended, { provide: { hasRepositoryMirrorsFeature: true } });
      expect(findMirrorCheckbox().attributes('disabled')).toBeUndefined();
    });

    it('is not rendered when ciCdOnly connection', () => {
      createComponent(shallowMountExtended, { provide: { ciCdOnly: true } });
      expect(findMirrorCheckbox().exists()).toBe(false);
    });
  });
});
