import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { ALERT_LOCALSTORAGE_KEY } from '~/jira_connect/subscriptions/constants';
import {
  persistAlert,
  retrieveAlert,
  getJwt,
  reloadPage,
  sizeToParent,
} from '~/jira_connect/subscriptions/utils';

describe('JiraConnect utils', () => {
  describe('alert utils', () => {
    useLocalStorageSpy();

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

  describe('AP object utils', () => {
    afterEach(() => {
      global.AP = null;
    });

    describe('getJwt', () => {
      const mockJwt = 'jwt';
      const getTokenSpy = jest.fn((callback) => callback(mockJwt));

      it('resolves to the function call when AP.context.getToken is a function', async () => {
        global.AP = {
          context: {
            getToken: getTokenSpy,
          },
        };

        const jwt = await getJwt();

        expect(getTokenSpy).toHaveBeenCalled();
        expect(jwt).toBe(mockJwt);
      });

      it('resolves to undefined when AP.context.getToken is not a function', async () => {
        const jwt = await getJwt();

        expect(getTokenSpy).not.toHaveBeenCalled();
        expect(jwt).toBeUndefined();
      });
    });

    describe('reloadPage', () => {
      const reloadSpy = jest.fn();

      useMockLocationHelper();

      it('calls the function when AP.navigator.reload is a function', async () => {
        global.AP = {
          navigator: {
            reload: reloadSpy,
          },
        };

        await reloadPage();

        expect(reloadSpy).toHaveBeenCalled();
        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('calls window.location.reload when AP.navigator.reload is not a function', async () => {
        await reloadPage();

        expect(reloadSpy).not.toHaveBeenCalled();
        expect(window.location.reload).toHaveBeenCalled();
      });
    });

    describe('sizeToParent', () => {
      const sizeToParentSpy = jest.fn();

      it('calls the function when AP.sizeToParent is a function', async () => {
        global.AP = {
          sizeToParent: sizeToParentSpy,
        };

        await sizeToParent();

        expect(sizeToParentSpy).toHaveBeenCalled();
      });

      it('does nothing when AP.navigator.reload is not a function', async () => {
        await sizeToParent();

        expect(sizeToParentSpy).not.toHaveBeenCalled();
      });
    });
  });
});
