import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initForm from '~/pages/projects/pages_domains/form';

const ENABLED_UNLESS_AUTO_SSL_CLASS = 'js-enabled-unless-auto-ssl';
const SSL_TOGGLE_CLASS = 'js-enable-ssl-gl-toggle';
const SSL_TOGGLE_INPUT_CLASS = 'js-project-feature-toggle-input';
const SHOW_IF_AUTO_SSL_CLASS = 'js-shown-if-auto-ssl';
const SHOW_UNLESS_AUTO_SSL_CLASS = 'js-shown-unless-auto-ssl';
const HIDDEN_CLASS = '!gl-hidden';

describe('Page domains form', () => {
  let toggle;

  const findEnabledUnless = () => document.querySelector(`.${ENABLED_UNLESS_AUTO_SSL_CLASS}`);
  const findSslToggle = () => document.querySelector(`.${SSL_TOGGLE_CLASS} button`);
  const findSslToggleInput = () => document.querySelector(`.${SSL_TOGGLE_INPUT_CLASS}`);
  const findIfAutoSsl = () => document.querySelector(`.${SHOW_IF_AUTO_SSL_CLASS}`);
  const findUnlessAutoSsl = () => document.querySelector(`.${SHOW_UNLESS_AUTO_SSL_CLASS}`);

  const create = () => {
    setHTMLFixture(`
      <form>
        <span
          class="${SSL_TOGGLE_CLASS}"
          data-label="SSL toggle"
          ></span>
        <input class="${SSL_TOGGLE_INPUT_CLASS}" type="hidden" />
        <span class="${SHOW_UNLESS_AUTO_SSL_CLASS}"></span>
        <span class="${SHOW_IF_AUTO_SSL_CLASS}"></span>
        <button class="${ENABLED_UNLESS_AUTO_SSL_CLASS}"></button>
      </form>
    `);
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  it('instantiates the toggle', () => {
    create();
    initForm();

    expect(findSslToggle()).not.toBe(null);
  });

  describe('when auto SSL is enabled', () => {
    beforeEach(() => {
      create();
      toggle = initForm();
      toggle.$emit('change', true);
    });

    it('sets the correct classes', () => {
      expect(Array.from(findIfAutoSsl().classList)).not.toContain(HIDDEN_CLASS);
      expect(Array.from(findUnlessAutoSsl().classList)).toContain(HIDDEN_CLASS);
    });

    it('sets the correct disabled value', () => {
      expect(findEnabledUnless().getAttribute('disabled')).toBe('disabled');
    });

    it('sets the correct value for the input', () => {
      expect(findSslToggleInput().getAttribute('value')).toBe('true');
    });
  });

  describe('when auto SSL is not enabled', () => {
    beforeEach(() => {
      create();
      toggle = initForm();
      toggle.$emit('change', false);
    });

    it('sets the correct classes', () => {
      expect(Array.from(findIfAutoSsl().classList)).toContain(HIDDEN_CLASS);
      expect(Array.from(findUnlessAutoSsl().classList)).not.toContain(HIDDEN_CLASS);
    });

    it('sets the correct disabled value', () => {
      expect(findUnlessAutoSsl().getAttribute('disabled')).toBe(null);
    });

    it('sets the correct value for the input', () => {
      expect(findSslToggleInput().getAttribute('value')).toBe('false');
    });
  });
});
