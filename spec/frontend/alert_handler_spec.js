import { setHTMLFixture } from 'helpers/fixtures';
import initAlertHandler from '~/alert_handler';

describe('Alert Handler', () => {
  const ALERT_SELECTOR = 'gl-alert';
  const CLOSE_SELECTOR = 'gl-alert-dismiss';
  const ALERT_HTML = `<div class="${ALERT_SELECTOR}"><button class="${CLOSE_SELECTOR}">Dismiss</button></div>`;

  const findFirstAlert = () => document.querySelector(`.${ALERT_SELECTOR}`);
  const findAllAlerts = () => document.querySelectorAll(`.${ALERT_SELECTOR}`);
  const findFirstCloseButton = () => document.querySelector(`.${CLOSE_SELECTOR}`);

  describe('initAlertHandler', () => {
    describe('with one alert', () => {
      beforeEach(() => {
        setHTMLFixture(ALERT_HTML);
        initAlertHandler();
      });

      it('should render the alert', () => {
        expect(findFirstAlert()).toExist();
      });

      it('should dismiss the alert on click', () => {
        findFirstCloseButton().click();
        expect(findFirstAlert()).not.toExist();
      });
    });

    describe('with two alerts', () => {
      beforeEach(() => {
        setHTMLFixture(ALERT_HTML + ALERT_HTML);
        initAlertHandler();
      });

      it('should render two alerts', () => {
        expect(findAllAlerts()).toHaveLength(2);
      });

      it('should dismiss only one alert on click', () => {
        findFirstCloseButton().click();
        expect(findAllAlerts()).toHaveLength(1);
      });
    });
  });
});
