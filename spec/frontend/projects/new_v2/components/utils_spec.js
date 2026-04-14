import MockAdapter from 'axios-mock-adapter';
import { checkRepositoryConnection } from '~/projects/new_v2/components/utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('checkRepositoryConnection', () => {
  let mockAxios;
  const mockValidatePath = '/import/url/validate';
  const mockCredentials = {
    url: 'https://gitlab.com/group/project.git',
    user: 'testuser',
    password: 'testpassword',
  };

  const mockPost = (status, data) => mockAxios.onPost(mockValidatePath).reply(status, data);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('when URL is not reasonably valid', () => {
    it('returns isValid as false and does not POST to axios', async () => {
      const result = await checkRepositoryConnection(mockValidatePath, {
        ...mockCredentials,
        url: 'not a valid url',
      });

      expect(result).toEqual({ isValid: false, success: false, message: null });
      expect(mockAxios.history.post).toHaveLength(0);
    });
  });

  describe('when URL is reasonably valid', () => {
    describe('when connection is successful', () => {
      beforeEach(() => {
        mockPost(HTTP_STATUS_OK, { success: true, message: 'Connection successful' });
      });

      it('returns success response', async () => {
        const result = await checkRepositoryConnection(mockValidatePath, mockCredentials);

        expect(result).toEqual({ isValid: true, success: true, message: 'Connection successful' });
      });

      it('sends correct request payload', async () => {
        await checkRepositoryConnection(mockValidatePath, mockCredentials);

        expect(mockAxios.history.post[0].data).toBe(JSON.stringify(mockCredentials));
      });
    });

    describe('when connection fails', () => {
      it('returns isValid: true, success: false, and the response error message', async () => {
        mockPost(HTTP_STATUS_OK, { success: false, message: 'Invalid credentials' });

        const result = await checkRepositoryConnection(mockValidatePath, mockCredentials);

        expect(result).toEqual({ isValid: true, success: false, message: 'Invalid credentials' });
      });
    });

    describe('when connection throws network error', () => {
      it('returns network error message', async () => {
        mockAxios.onPost(mockValidatePath).networkError();

        const result = await checkRepositoryConnection(mockValidatePath, mockCredentials);

        expect(result).toEqual({ isValid: true, success: false, message: 'Network Error' });
      });
    });
  });
});
