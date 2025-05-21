import { GlFormInputGroup } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImportByUrlForm from '~/projects/new_v2/components/import_by_url_form.vue';
import SharedProjectCreationFields from '~/projects/new_v2/components/shared_project_creation_fields.vue';

const $toast = {
  show: jest.fn(),
};

describe('Import Project by URL Form', () => {
  let wrapper;
  let mockAxios;

  const mockImportByUrlValidatePath = '/import/url/validate';
  const defaultProps = {
    namespace: {
      id: '1',
      fullPath: 'root',
      isPersonal: true,
    },
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(ImportByUrlForm, {
      provide: {
        importByUrlValidatePath: mockImportByUrlValidatePath,
      },
      propsData: defaultProps,
      mocks: {
        $toast,
      },
      stubs: {
        GlFormInputGroup,
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
  const findUsernameInput = () => wrapper.findByTestId('repository-username');
  const findPasswordInput = () => wrapper.findByTestId('repository-password');
  const findCheckConnectionButton = () => wrapper.findByTestId('check-connection');
  const findSharedFields = () => wrapper.findComponent(SharedProjectCreationFields);

  it('renders URL, username, password fields', () => {
    expect(findUrlInput().exists()).toBe(true);
    expect(findUsernameInput().exists()).toBe(true);
    expect(findPasswordInput().exists()).toBe(true);
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

  it('renders shared fields', () => {
    const sharedFields = findSharedFields();
    expect(sharedFields.exists()).toBe(true);
    expect(sharedFields.props('namespace')).toEqual(defaultProps.namespace);
  });

  it('emits onSelectNamespace event when shared fields emits it', () => {
    const newNamespace = { id: '2', fullPath: 'new-namespace', isPersonal: false };

    findSharedFields().vm.$emit('onSelectNamespace', newNamespace);

    expect(wrapper.emitted('onSelectNamespace')).toEqual([[newNamespace]]);
  });

  it('renders the option to move to Next Step', () => {
    expect(findNextButton().text()).toBe('Next step');
  });

  it(`emits the "back" event when the back button is clicked`, () => {
    findBackButton().vm.$emit('click');
    expect(wrapper.emitted('back')).toHaveLength(1);
  });
});
