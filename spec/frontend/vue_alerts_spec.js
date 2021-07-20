import Vue from 'vue';
import { setHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import initVueAlerts from '~/vue_alerts';

describe('VueAlerts', () => {
  const alerts = [
    {
      title: 'Lorem',
      html: 'Lorem <strong>Ipsum</strong>',
      dismissible: true,
      primaryButtonText: 'Okay!',
      primaryButtonLink: `${TEST_HOST}/okay`,
      variant: 'tip',
    },
    {
      title: 'Hello',
      html: 'Hello <strong>World</strong>',
      dismissible: false,
      primaryButtonText: 'No!',
      primaryButtonLink: `${TEST_HOST}/no`,
      variant: 'info',
    },
  ];

  beforeEach(() => {
    setHTMLFixture(
      alerts
        .map(
          (x) => `
    <div class="js-vue-alert"
      data-dismissible="${x.dismissible}"
      data-title="${x.title}"
      data-primary-button-text="${x.primaryButtonText}"
      data-primary-button-link="${x.primaryButtonLink}"
      data-variant="${x.variant}">${x.html}</div>
    `,
        )
        .join('\n'),
    );
  });

  const findJsHooks = () => document.querySelectorAll('.js-vue-alert');
  const findAlerts = () => document.querySelectorAll('.gl-alert');
  const findAlertDismiss = (alert) => alert.querySelector('.gl-dismiss-btn');

  const serializeAlert = (alert) => ({
    title: alert.querySelector('.gl-alert-title').textContent.trim(),
    html: alert.querySelector('.gl-alert-body div').innerHTML,
    dismissible: Boolean(alert.querySelector('.gl-dismiss-btn')),
    primaryButtonText: alert.querySelector('.gl-alert-action').textContent.trim(),
    primaryButtonLink: alert.querySelector('.gl-alert-action').href,
    variant: [...alert.classList]
      .find((x) => x.match(/gl-alert-(?!not-dismissible)/))
      .replace('gl-alert-', ''),
  });

  it('starts with only JsHooks', () => {
    expect(findJsHooks().length).toEqual(alerts.length);
    expect(findAlerts().length).toEqual(0);
  });

  describe('when mounted', () => {
    beforeEach(() => {
      initVueAlerts();
    });

    it('replaces JsHook with GlAlert', () => {
      expect(findJsHooks().length).toEqual(0);
      expect(findAlerts().length).toEqual(alerts.length);
    });

    it('passes along props to gl-alert', () => {
      expect([...findAlerts()].map(serializeAlert)).toEqual(alerts);
    });

    describe('when dismissed', () => {
      beforeEach(() => {
        findAlertDismiss(findAlerts()[0]).click();

        return Vue.nextTick();
      });

      it('hides the alert', () => {
        expect(findAlerts().length).toEqual(alerts.length - 1);
      });
    });
  });
});
