import { GlButton, GlForm } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

// main.js is the application entry point, so importing it boots rails-ujs against the slim
// jQuery build used in Jest, which has no `ajaxPrefilter`.
jest.mock('~/lib/utils/rails_ujs', () => ({ initRails: jest.fn() }));

describe('main', () => {
  beforeAll(async () => {
    await import('~/main');
  });

  describe('auto-disabling submit buttons', () => {
    const findForm = () => document.querySelector('form');
    const findButton = () => document.querySelector('button[type="submit"]');
    const isDisabled = () => findButton().disabled;

    const submitForm = () =>
      findForm().dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    const fireRailsEvent = (name) =>
      findForm().dispatchEvent(new CustomEvent(name, { bubbles: true }));

    afterEach(() => {
      resetHTMLFixture();
    });

    describe('when a server-rendered form is submitted', () => {
      beforeEach(() => {
        setHTMLFixture('<form><button type="submit">Save</button></form>');
        submitForm();
      });

      it('disables the submit button', () => {
        expect(isDisabled()).toBe(true);
        expect(findButton().classList).toContain('disabled');
      });

      it('re-enables the submit button once the request completes', () => {
        fireRailsEvent('ajax:complete');

        expect(isDisabled()).toBe(false);
        expect(findButton().classList).not.toContain('disabled');
      });
    });

    describe('when a rails-ujs remote form starts a request', () => {
      beforeEach(() => {
        setHTMLFixture('<form><button type="submit">Save</button></form>');
        fireRailsEvent('ajax:beforeSend');
      });

      it('disables the submit button', () => {
        expect(isDisabled()).toBe(true);
      });

      it('re-enables the submit button once the request completes', () => {
        fireRailsEvent('ajax:complete');

        expect(isDisabled()).toBe(false);
      });
    });

    describe('when the form handles its own submit', () => {
      beforeEach(() => {
        setHTMLFixture('<form><button type="submit">Save</button></form>');
        findForm().addEventListener('submit', (e) => e.preventDefault());
        submitForm();
      });

      it('leaves the submit button alone', () => {
        expect(isDisabled()).toBe(false);
        expect(findButton().classList).not.toContain('disabled');
      });
    });

    describe('when the button opts out with js-no-auto-disable', () => {
      beforeEach(() => {
        setHTMLFixture(
          '<form><button type="submit" class="js-no-auto-disable">Save</button></form>',
        );
        submitForm();
      });

      it('leaves the submit button alone', () => {
        expect(isDisabled()).toBe(false);
      });
    });

    describe('when the button reports its state with aria-disabled', () => {
      beforeEach(() => {
        setHTMLFixture(
          '<form><button type="submit" aria-disabled="true" class="disabled">Save</button></form>',
        );
        fireRailsEvent('ajax:beforeSend');
        fireRailsEvent('ajax:complete');
      });

      it('does not clear the disabled state the component set', () => {
        expect(findButton().classList).toContain('disabled');
      });
    });

    // GlButton emits aria-disabled="false" on non-standard tags, so the exclusion has to
    // match the value rather than the attribute.
    describe('when the button reports aria-disabled false', () => {
      beforeEach(() => {
        setHTMLFixture('<form><button type="submit" aria-disabled="false">Save</button></form>');
        submitForm();
      });

      it('still disables the submit button', () => {
        expect(isDisabled()).toBe(true);
      });
    });

    describe('when a Vue form submits through axios', () => {
      beforeEach(() => {
        mount(
          {
            components: { GlForm, GlButton },
            methods: { onSubmit() {} },
            template: `
              <gl-form @submit.prevent="onSubmit">
                <gl-button type="submit">Verify code</gl-button>
              </gl-form>
            `,
          },
          { attachTo: document.body },
        );

        submitForm();
      });

      // GlButton renders `aria-disabled` instead of the native attribute, so a re-render no
      // longer clears a `disabled` set from here and the button would stay stuck.
      it('does not leave the button stuck in a disabled state', () => {
        expect(isDisabled()).toBe(false);
        expect(findButton().classList).not.toContain('disabled');
      });
    });
  });
});
