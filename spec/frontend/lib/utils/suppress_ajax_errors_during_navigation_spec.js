import waitForPromises from 'helpers/wait_for_promises';
import suppressAjaxErrorsDuringNavigation from '~/lib/utils/suppress_ajax_errors_during_navigation';

describe('suppressAjaxErrorsDuringNavigation', () => {
  const OTHER_ERR_CODE = 'foo';
  const NAV_ERR_CODE = 'ECONNABORTED';

  it.each`
    isUserNavigating | code
    ${false}         | ${OTHER_ERR_CODE}
    ${false}         | ${NAV_ERR_CODE}
    ${true}          | ${OTHER_ERR_CODE}
  `('should return a rejected Promise', ({ isUserNavigating, code }) => {
    const err = { code };
    const actual = suppressAjaxErrorsDuringNavigation(err, isUserNavigating);

    return expect(actual).rejects.toBe(err);
  });

  it('should return a Promise that never resolves', () => {
    const err = { code: NAV_ERR_CODE };
    const actual = suppressAjaxErrorsDuringNavigation(err, true);

    const thenCallback = jest.fn();
    const catchCallback = jest.fn();
    actual.then(thenCallback).catch(catchCallback);

    return waitForPromises().then(() => {
      expect(thenCallback).not.toHaveBeenCalled();
      expect(catchCallback).not.toHaveBeenCalled();
    });
  });
});
