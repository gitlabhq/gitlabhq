import { GlTableLite } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import AuthLog from '~/token_access/components/auth_log.vue';
import getAuthLogsQuery from '~/token_access/graphql/queries/get_auth_logs.query.graphql';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { mockAuthLogsResponse } from './mock_data';

const projectPath = 'root/my-repo';
const csvDownloadPath = '/root/my-repo/-/settings/ci_cd/export_job_token_authorizations';
const message = 'An error occurred';
const error = new Error(message);

Vue.use(VueApollo);

jest.mock('~/alert');

describe('TokenAccess component', () => {
  let wrapper;

  const getAuthLogsQueryResponseHandler = jest.fn().mockResolvedValue(mockAuthLogsResponse());
  const getAuthLogsQueryEmptyResponseHandler = jest.fn().mockResolvedValue();
  const failureHandler = jest.fn().mockRejectedValue(error);

  const createMockApolloProvider = (requestHandlers) => {
    return createMockApollo(requestHandlers);
  };
  const mockToastShow = jest.fn();

  const findGlTable = () => wrapper.findComponent(GlTableLite);
  const findAllTableRows = () => wrapper.findAllByTestId('auth-logs-table-row');
  const findCrudComponentBody = () => wrapper.findByTestId('crud-body');
  const findDownloadButton = () => wrapper.findByTestId('auth-log-download-csv-button');
  const findPagination = () => wrapper.findByTestId('auth-log-pagination');

  const createComponent = (requestHandlers, mountFn = shallowMountExtended) => {
    wrapper = mountFn(AuthLog, {
      provide: {
        fullPath: projectPath,
        csvDownloadPath,
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
      stubs: { CrudComponent },
    });
  };

  describe('queries', () => {
    it('fetches the authentication events correctly', async () => {
      const expectedVariables = {
        fullPath: projectPath,
        after: null,
        before: null,
        first: 20,
        last: null,
      };

      createComponent([[getAuthLogsQuery, getAuthLogsQueryResponseHandler]], mountExtended);

      await waitForPromises();

      expect(getAuthLogsQueryResponseHandler).toHaveBeenCalledWith(expectedVariables);
    });

    it('handles fetch scope error correctly', async () => {
      createComponent([[getAuthLogsQuery, failureHandler]]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching authentication logs.',
      });
    });
  });

  describe('Authentication log', () => {
    it('displays an empty state when no data is available', async () => {
      createComponent([[getAuthLogsQuery, getAuthLogsQueryEmptyResponseHandler]], mountExtended);

      await waitForPromises();

      expect(findCrudComponentBody().text()).toContain(
        'No authentication events in the last 30 days.',
      );
    });

    it('displays a table when data is available', async () => {
      createComponent([[getAuthLogsQuery, getAuthLogsQueryResponseHandler]], mountExtended);

      await waitForPromises();

      expect(findGlTable().exists()).toBe(true);
      expect(findAllTableRows()).toHaveLength(
        mockAuthLogsResponse().data.project.ciJobTokenAuthLogs.nodes.length,
      );
    });

    it('displays pagination controls', async () => {
      const getAuthLogsQueryResponseHandlerWithPagination = jest
        .fn()
        .mockResolvedValue(mockAuthLogsResponse(true));

      createComponent(
        [[getAuthLogsQuery, getAuthLogsQueryResponseHandlerWithPagination]],
        mountExtended,
      );

      await waitForPromises();

      expect(findPagination().exists()).toBe(true);
    });

    it('displays a download button when there is at least one event available', async () => {
      createComponent([[getAuthLogsQuery, getAuthLogsQueryResponseHandler]], mountExtended);

      await waitForPromises();

      expect(findDownloadButton().exists()).toBe(true);
      expect(findDownloadButton().props()).toEqual(
        expect.objectContaining({
          isUnsafeLink: true,
          category: 'primary',
          variant: 'default',
          size: 'small',
        }),
      );
    });
  });
});
