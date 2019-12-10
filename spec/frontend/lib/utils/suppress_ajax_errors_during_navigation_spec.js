import waitForPromises from 'helpers/wait_for_promises';
import suppressAjaxErrorsDuringNavigation from '~/lib/utils/suppress_ajax_errors_during_navigation';

describe('suppressAjaxErrorsDuringNavigation', () => {
  const OTHER_ERR_CODE = 'foo';
  const NAV_ERR_CODE = 'ECONNABORTED';

  it.each`
    isFeatureFlagEnabled | isUserNavigating | code
    ${false}             | ${false}         | ${OTHER_ERR_CODE}
    ${false}             | ${false}         | ${NAV_ERR_CODE}
    ${false}             | ${true}          | ${OTHER_ERR_CODE}
    ${false}             | ${true}          | ${NAV_ERR_CODE}
    ${true}              | ${false}         | ${OTHER_ERR_CODE}
    ${true}              | ${false}         | ${NAV_ERR_CODE}
    ${true}              | ${true}          | ${OTHER_ERR_CODE}
  `('should return a rejected Promise', ({ isFeatureFlagEnabled, isUserNavigating, code }) => {
    const err = { code };
    const actual = suppressAjaxErrorsDuringNavigation(err, isUserNavigating, isFeatureFlagEnabled);

    return expect(actual).rejects.toBe(err);
  });

  it('should return a Promise that never resolves', () => {
    const err = { code: NAV_ERR_CODE };
    const actual = suppressAjaxErrorsDuringNavigation(err, true, true);

    const thenCallback = jest.fn();
    const catchCallback = jest.fn();
    actual.then(thenCallback).catch(catchCallback);

    return waitForPromises().then(() => {
      expect(thenCallback).not.toHaveBeenCalled();
      expect(catchCallback).not.toHaveBeenCalled();
    });
  });
});
