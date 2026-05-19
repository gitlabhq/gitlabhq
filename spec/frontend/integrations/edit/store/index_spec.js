import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import {
  I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
  integrationLevels,
} from '~/integrations/constants';
import { useIntegrationForm } from '~/integrations/edit/store';
import { mockIntegrationProps, mockJiraIssueTypes } from '../mock_data';

jest.mock('~/lib/utils/url_utility');

describe('Integration form store', () => {
  let store;
  let axiosMock;

  beforeAll(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
  });

  afterAll(() => {
    axiosMock.restore();
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useIntegrationForm();
  });

  describe('initial state', () => {
    it('has the expected defaults', () => {
      expect(store.$state).toEqual({
        defaultState: null,
        customState: {},
        override: false,
        isLoadingJiraIssueTypes: false,
        jiraIssueTypes: [],
        loadingJiraIssueTypesErrorMessage: '',
      });
    });
  });

  describe('getters', () => {
    const customState = { ...mockIntegrationProps, type: 'CustomState' };
    const defaultState = { ...mockIntegrationProps, type: 'DefaultState' };

    beforeEach(() => {
      store.customState = customState;
    });

    describe('isInheriting', () => {
      describe('when defaultState is null', () => {
        it('returns false', () => {
          expect(store.isInheriting).toBe(false);
        });
      });

      describe('when defaultState is an object', () => {
        beforeEach(() => {
          store.defaultState = defaultState;
        });

        describe('when override is false', () => {
          beforeEach(() => {
            store.override = false;
          });

          it('returns true', () => {
            expect(store.isInheriting).toBe(true);
          });
        });

        describe('when override is true', () => {
          beforeEach(() => {
            store.override = true;
          });

          it('returns false', () => {
            expect(store.isInheriting).toBe(false);
          });
        });
      });
    });

    describe('isProjectLevel', () => {
      it.each`
        integrationLevel              | expected
        ${integrationLevels.PROJECT}  | ${true}
        ${integrationLevels.GROUP}    | ${false}
        ${integrationLevels.INSTANCE} | ${false}
      `('when integrationLevel is `$integrationLevel`', ({ integrationLevel, expected }) => {
        store.customState = { ...customState, integrationLevel };
        expect(store.isProjectLevel).toBe(expected);
      });
    });

    describe('propsSource', () => {
      beforeEach(() => {
        store.defaultState = defaultState;
      });

      it('equals defaultState if inheriting', () => {
        store.override = false;
        expect(store.propsSource).toEqual(defaultState);
      });

      it('equals customState if not inheriting', () => {
        store.override = true;
        expect(store.propsSource).toEqual(customState);
      });
    });

    describe('currentKey', () => {
      beforeEach(() => {
        store.defaultState = defaultState;
      });

      it('equals `admin` if inheriting', () => {
        store.override = false;
        expect(store.currentKey).toBe('admin');
      });

      it('equals `custom` if not inheriting', () => {
        store.override = true;
        expect(store.currentKey).toBe('custom');
      });
    });
  });

  describe('actions', () => {
    describe('setOverride', () => {
      it('sets override', () => {
        store.setOverride(true);

        expect(store.override).toBe(true);
      });
    });

    describe('requestJiraIssueTypes', () => {
      const mockTestPath = '/test';

      beforeEach(() => {
        store.customState = { testPath: mockTestPath };
      });

      describe.each`
        scenario                                                        | responseCode | response                                                                                 | expectedErrorMessage                              | expectedIssueTypes
        ${'when successful'}                                            | ${200}       | ${{ issuetypes: mockJiraIssueTypes }}                                                    | ${''}                                             | ${mockJiraIssueTypes}
        ${'when response has no issue types'}                           | ${200}       | ${{ issuetypes: [] }}                                                                    | ${I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE} | ${[]}
        ${'when response includes error w/ no message'}                 | ${200}       | ${{ error: true }}                                                                       | ${I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE} | ${[]}
        ${'when response includes error w/ message'}                    | ${200}       | ${{ error: true, message: 'Validation failed' }}                                         | ${'Validation failed'}                            | ${[]}
        ${'when response includes error w/ message & service_response'} | ${200}       | ${{ error: true, message: 'Validation failed', service_response: "Url can't be blank" }} | ${"Url can't be blank"}                           | ${[]}
      `('$scenario', ({ responseCode, response, expectedErrorMessage, expectedIssueTypes }) => {
        beforeEach(() => {
          axiosMock.onPut(mockTestPath).replyOnce(responseCode, response);
        });

        it('updates state accordingly', async () => {
          await store.requestJiraIssueTypes(new FormData());

          expect(store.jiraIssueTypes).toEqual(expectedIssueTypes);
          expect(store.loadingJiraIssueTypesErrorMessage).toBe(expectedErrorMessage);
          expect(store.isLoadingJiraIssueTypes).toBe(false);
        });
      });

      describe('when error occurs', () => {
        beforeEach(() => {
          axiosMock.onPut(mockTestPath).replyOnce(500, {});
        });

        it('resets issue types, sets an error message, and resets loading flag', async () => {
          await store.requestJiraIssueTypes(new FormData());

          expect(store.jiraIssueTypes).toEqual([]);
          expect(store.loadingJiraIssueTypesErrorMessage).toEqual(expect.any(String));
          expect(store.isLoadingJiraIssueTypes).toBe(false);
        });
      });
    });
  });
});
