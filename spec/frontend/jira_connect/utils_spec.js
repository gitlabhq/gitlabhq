import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { ALERT_LOCALSTORAGE_KEY } from '~/jira_connect/constants';
import { persistAlert, retrieveAlert } from '~/jira_connect/utils';

useLocalStorageSpy();

describe('JiraConnect utils', () => {
  describe('alert utils', () => {
    it.each`
      arg                                                                                 | expectedRetrievedValue
      ${{ title: 'error' }}                                                               | ${{ title: 'error' }}
      ${{ title: 'error', randomKey: 'test' }}                                            | ${{ title: 'error' }}
      ${{ title: 'error', message: 'error message', linkUrl: 'link', variant: 'danger' }} | ${{ title: 'error', message: 'error message', linkUrl: 'link', variant: 'danger' }}
      ${undefined}                                                                        | ${{}}
    `(
      'persists and retrieves alert data from localStorage when arg is $arg',
      ({ arg, expectedRetrievedValue }) => {
        persistAlert(arg);

        expect(localStorage.setItem).toHaveBeenCalledWith(
          ALERT_LOCALSTORAGE_KEY,
          JSON.stringify(expectedRetrievedValue),
        );

        const retrievedValue = retrieveAlert();

        expect(localStorage.getItem).toHaveBeenCalledWith(ALERT_LOCALSTORAGE_KEY);
        expect(retrievedValue).toEqual(expectedRetrievedValue);
      },
    );
  });
});
