import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import testAction from 'helpers/vuex_action_helper';
import { I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE } from '~/integrations/constants';
import {
  setOverride,
  requestJiraIssueTypes,
  receiveJiraIssueTypesSuccess,
  receiveJiraIssueTypesError,
} from '~/integrations/edit/store/actions';
import * as types from '~/integrations/edit/store/mutation_types';
import createState from '~/integrations/edit/store/state';
import { mockJiraIssueTypes } from '../mock_data';

jest.mock('~/lib/utils/url_utility');

describe('Integration form store actions', () => {
  let state;
  let mockAxios;

  beforeEach(() => {
    state = createState();
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('setOverride', () => {
    it('should commit override mutation', () => {
      return testAction(setOverride, true, state, [{ type: types.SET_OVERRIDE, payload: true }]);
    });
  });

  describe('requestJiraIssueTypes', () => {
    describe.each`
      scenario                                                        | responseCode | response                                                                                 | action
      ${'when successful'}                                            | ${200}       | ${{ issuetypes: mockJiraIssueTypes }}                                                    | ${{ type: 'receiveJiraIssueTypesSuccess', payload: mockJiraIssueTypes }}
      ${'when response has no issue types'}                           | ${200}       | ${{ issuetypes: [] }}                                                                    | ${{ type: 'receiveJiraIssueTypesError', payload: I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE }}
      ${'when response includes error w/ no message'}                 | ${200}       | ${{ error: true }}                                                                       | ${{ type: 'receiveJiraIssueTypesError', payload: I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE }}
      ${'when response includes error w/ message'}                    | ${200}       | ${{ error: true, message: 'Validation failed' }}                                         | ${{ type: 'receiveJiraIssueTypesError', payload: 'Validation failed' }}
      ${'when response includes error w/ message & service_response'} | ${200}       | ${{ error: true, message: 'Validation failed', service_response: "Url can't be blank" }} | ${{ type: 'receiveJiraIssueTypesError', payload: "Url can't be blank" }}
      ${'when error occurs'}                                          | ${500}       | ${{}}                                                                                    | ${{ type: 'receiveJiraIssueTypesError', payload: expect.any(String) }}
    `('$scenario', ({ responseCode, response, action }) => {
      it(`should commit SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE and SET_IS_LOADING_JIRA_ISSUE_TYPES mutations, and dispatch ${action.type}`, () => {
        mockAxios.onPut('/test').replyOnce(responseCode, response);

        return testAction(
          requestJiraIssueTypes,
          new FormData(),
          { propsSource: { testPath: '/test' } },
          [
            // should clear the error messages and set the loading state
            { type: types.SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE, payload: '' },
            { type: types.SET_IS_LOADING_JIRA_ISSUE_TYPES, payload: true },
          ],
          [action],
        );
      });
    });
  });

  describe('receiveJiraIssueTypesSuccess', () => {
    it('should commit SET_IS_LOADING_JIRA_ISSUE_TYPES and SET_JIRA_ISSUE_TYPES mutations', () => {
      const issueTypes = ['issue', 'epic'];
      return testAction(receiveJiraIssueTypesSuccess, issueTypes, state, [
        { type: types.SET_IS_LOADING_JIRA_ISSUE_TYPES, payload: false },
        { type: types.SET_JIRA_ISSUE_TYPES, payload: issueTypes },
      ]);
    });
  });

  describe('receiveJiraIssueTypesError', () => {
    it('should commit SET_IS_LOADING_JIRA_ISSUE_TYPES, SET_JIRA_ISSUE_TYPES and SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE mutations', () => {
      const errorMessage = 'something went wrong';
      return testAction(receiveJiraIssueTypesError, errorMessage, state, [
        { type: types.SET_IS_LOADING_JIRA_ISSUE_TYPES, payload: false },
        { type: types.SET_JIRA_ISSUE_TYPES, payload: [] },
        { type: types.SET_JIRA_ISSUE_TYPES_ERROR_MESSAGE, payload: errorMessage },
      ]);
    });
  });
});
