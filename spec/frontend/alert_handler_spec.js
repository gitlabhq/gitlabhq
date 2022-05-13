import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initAlertHandler from '~/alert_handler';

describe('Alert Handler', () => {
  const ALERT_CLASS = 'gl-alert';
  const BANNER_CLASS = 'gl-banner';
  const DISMISS_CLASS = 'gl-alert-dismiss';
  const DISMISS_LABEL = 'Dismiss';

  const generateHtml = (parentClass) =>
    `<div class="${parentClass}">
      <button aria-label="${DISMISS_LABEL}">Dismiss</button>
    </div>`;

  const findFirstAlert = () => document.querySelector(`.${ALERT_CLASS}`);
  const findFirstBanner = () => document.querySelector(`.${BANNER_CLASS}`);
  const findAllAlerts = () => document.querySelectorAll(`.${ALERT_CLASS}`);
  const findFirstDismissButton = () => document.querySelector(`[aria-label="${DISMISS_LABEL}"]`);
  const findFirstDismissButtonByClass = () => document.querySelector(`.${DISMISS_CLASS}`);

  describe('initAlertHandler', () => {
    describe('with one alert', () => {
      beforeEach(() => {
        setHTMLFixture(generateHtml(ALERT_CLASS));
        initAlertHandler();
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('should render the alert', () => {
        expect(findFirstAlert()).not.toBe(null);
      });

      it('should dismiss the alert on click', () => {
        findFirstDismissButton().click();
        expect(findFirstAlert()).toBe(null);
      });
    });

    describe('with two alerts', () => {
      beforeEach(() => {
        setHTMLFixture(generateHtml(ALERT_CLASS) + generateHtml(ALERT_CLASS));
        initAlertHandler();
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('should render two alerts', () => {
        expect(findAllAlerts()).toHaveLength(2);
      });

      it('should dismiss only one alert on click', () => {
        findFirstDismissButton().click();
        expect(findAllAlerts()).toHaveLength(1);
      });
    });

    describe('with a dismissible banner', () => {
      beforeEach(() => {
        setHTMLFixture(generateHtml(BANNER_CLASS));
        initAlertHandler();
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('should render the banner', () => {
        expect(findFirstBanner()).not.toBe(null);
      });

      it('should dismiss the banner on click', () => {
        findFirstDismissButton().click();
        expect(findFirstBanner()).toBe(null);
      });
    });

    // Dismiss buttons *should* have the correct aria labels, but some of them won't
    // because legacy code isn't always a11y compliant.
    // This tests that the fallback for the incorrectly labelled buttons works.
    describe('with a mislabelled dismiss button', () => {
      beforeEach(() => {
        setHTMLFixture(`<div class="${ALERT_CLASS}">
          <button class="${DISMISS_CLASS}">Dismiss</button>
        </div>`);
        initAlertHandler();
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('should render the banner', () => {
        expect(findFirstAlert()).not.toBe(null);
      });

      it('should dismiss the banner on click', () => {
        findFirstDismissButtonByClass().click();
        expect(findFirstAlert()).toBe(null);
      });
    });
  });
});
