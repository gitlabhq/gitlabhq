import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { sanitize } from '~/lib/dompurify';
import { createAlert, VARIANT_WARNING } from '~/alert';

jest.mock('~/lib/dompurify', () => ({
  sanitize: jest.fn((val) => val),
}));
jest.mock('~/sentry/sentry_browser_wrapper');

describe('Flash', () => {
  const findTextContent = (containerSelector = '.flash-container') =>
    document.querySelector(containerSelector).textContent.replace(/\s+/g, ' ').trim();

  describe('createAlert', () => {
    const mockMessage = 'a message';
    let alert;

    describe('no flash-container', () => {
      it('does not add to the DOM', () => {
        alert = createAlert({ message: mockMessage });

        expect(alert).toBeNull();
        expect(document.querySelector('.gl-alert')).toBeNull();
      });
    });

    describe('with flash-container', () => {
      beforeEach(() => {
        setHTMLFixture('<div class="flash-container"></div>');
      });

      afterEach(() => {
        if (alert) {
          alert.$destroy();
        }
        resetHTMLFixture();
      });

      it('adds alert element into the document by default', () => {
        alert = createAlert({ message: mockMessage });

        expect(findTextContent()).toBe(mockMessage);
        expect(document.querySelector('.flash-container .gl-alert')).not.toBeNull();
      });

      it('adds flash of a warning type', () => {
        alert = createAlert({ message: mockMessage, variant: VARIANT_WARNING });

        expect(
          document.querySelector('.flash-container .gl-alert.gl-alert-warning'),
        ).not.toBeNull();
      });

      it('escapes text', () => {
        alert = createAlert({ message: '<script>alert("a");</script>' });

        const html = document.querySelector('.flash-container').innerHTML;

        expect(html).toContain('&lt;script&gt;alert("a");&lt;/script&gt;');
        expect(html).not.toContain('<script>alert("a");</script>');
      });

      it('adds alert into specified container', () => {
        setHTMLFixture(`
            <div class="my-alert-container"></div>
            <div class="my-other-container"></div>
        `);

        alert = createAlert({ message: mockMessage, containerSelector: '.my-alert-container' });

        expect(document.querySelector('.my-alert-container .gl-alert')).not.toBeNull();
        expect(document.querySelector('.my-alert-container').innerText.trim()).toBe(mockMessage);

        expect(document.querySelector('.my-other-container .gl-alert')).toBeNull();
        expect(document.querySelector('.my-other-container').innerText.trim()).toBe('');
      });

      it('adds alert into specified parent', () => {
        setHTMLFixture(`
            <div id="my-parent">
              <div class="flash-container"></div>
            </div>
            <div id="my-other-parent">
              <div class="flash-container"></div>
            </div>
        `);

        alert = createAlert({ message: mockMessage, parent: document.getElementById('my-parent') });

        expect(document.querySelector('#my-parent .flash-container .gl-alert')).not.toBeNull();
        expect(document.querySelector('#my-parent .flash-container').innerText.trim()).toBe(
          mockMessage,
        );

        expect(document.querySelector('#my-other-parent .flash-container .gl-alert')).toBeNull();
        expect(document.querySelector('#my-other-parent .flash-container').innerText.trim()).toBe(
          '',
        );
      });

      it('removes element after clicking', () => {
        alert = createAlert({ message: mockMessage });

        expect(document.querySelector('.flash-container .gl-alert')).not.toBeNull();

        document.querySelector('.gl-dismiss-btn').click();

        expect(document.querySelector('.flash-container .gl-alert')).toBeNull();
      });

      it('does not capture error using Sentry', () => {
        alert = createAlert({
          message: mockMessage,
          captureError: false,
          error: new Error('Error!'),
        });

        expect(Sentry.captureException).not.toHaveBeenCalled();
      });

      it('captures error using Sentry', () => {
        alert = createAlert({
          message: mockMessage,
          captureError: true,
          error: new Error('Error!'),
        });

        expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
        expect(Sentry.captureException).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'Error!',
          }),
        );
      });

      describe('when dismissible', () => {
        it('renders dismiss button', () => {
          alert = createAlert({ message: mockMessage });

          expect(
            document.querySelector('.flash-container .gl-alert button.gl-dismiss-btn'),
          ).not.toBeNull();
        });
      });

      describe('when non-dismissible', () => {
        it('does not render dismiss button', () => {
          alert = createAlert({ message: mockMessage, dismissible: false });

          expect(
            document.querySelector('.flash-container .gl-alert button.gl-dismiss-btn'),
          ).toBeNull();
        });
      });

      describe('with title', () => {
        const mockTitle = 'my title';

        it('shows title and message', () => {
          createAlert({
            title: mockTitle,
            message: mockMessage,
          });

          expect(findTextContent()).toBe(`${mockTitle} ${mockMessage}`);
        });
      });

      describe('with buttons', () => {
        const findAlertAction = () => document.querySelector('.flash-container .gl-alert-action');

        it('adds primary button', () => {
          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              text: 'Ok',
            },
          });

          expect(findAlertAction().textContent.trim()).toBe('Ok');
        });

        it('creates link with href', () => {
          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              link: '/url',
              text: 'Ok',
            },
          });

          const action = findAlertAction();

          expect(action.textContent.trim()).toBe('Ok');
          expect(action.nodeName).toBe('A');
          expect(action.getAttribute('href')).toBe('/url');
        });

        it('create button as href when no href is present', () => {
          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              text: 'Ok',
            },
          });

          const action = findAlertAction();

          expect(action.nodeName).toBe('BUTTON');
          expect(action.getAttribute('href')).toBe(null);
        });

        it('escapes the title text', () => {
          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              text: '<script>alert("a")</script>',
            },
          });

          const html = findAlertAction().innerHTML;

          expect(html).toContain('&lt;script&gt;alert("a")&lt;/script&gt;');
          expect(html).not.toContain('<script>alert("a")</script>');
        });

        it('calls actionConfig clickHandler on click', () => {
          const clickHandler = jest.fn();

          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              text: 'Ok',
              clickHandler,
            },
          });

          expect(clickHandler).toHaveBeenCalledTimes(0);

          findAlertAction().click();

          expect(clickHandler).toHaveBeenCalledTimes(1);
          expect(clickHandler).toHaveBeenCalledWith(expect.any(MouseEvent));
        });
      });

      describe('Alert API', () => {
        describe('dismiss', () => {
          it('dismiss programmatically with .dismiss()', () => {
            expect(document.querySelector('.gl-alert')).toBeNull();

            alert = createAlert({ message: mockMessage });

            expect(document.querySelector('.gl-alert')).not.toBeNull();

            alert.dismiss();

            expect(document.querySelector('.gl-alert')).toBeNull();
          });

          it('does not crash if calling .dismiss() twice', () => {
            alert = createAlert({ message: mockMessage });

            alert.dismiss();
            expect(() => alert.dismiss()).not.toThrow();
          });

          it('calls onDismiss when dismissed', () => {
            const dismissHandler = jest.fn();

            alert = createAlert({ message: mockMessage, onDismiss: dismissHandler });

            expect(dismissHandler).toHaveBeenCalledTimes(0);

            alert.dismiss();

            expect(dismissHandler).toHaveBeenCalledTimes(1);
          });
        });
      });

      describe('when called multiple times', () => {
        it('clears previous alerts', () => {
          createAlert({ message: 'message 1' });
          createAlert({ message: 'message 2' });

          expect(findTextContent()).toBe('message 2');
        });

        it('preserves alerts when `preservePrevious` is true', () => {
          createAlert({ message: 'message 1' });
          createAlert({ message: 'message 2', preservePrevious: true });

          expect(findTextContent()).toBe('message 1 message 2');
        });
      });

      describe('with message links', () => {
        const findAlertMessageLinks = () =>
          Array.from(document.querySelectorAll('.flash-container a'));

        it('creates a link', () => {
          alert = createAlert({
            message: 'Read more at %{exampleLinkStart}example site%{exampleLinkEnd}.',
            messageLinks: {
              exampleLink: 'https://example.com',
            },
          });
          const messageLinks = findAlertMessageLinks();

          expect(messageLinks).toHaveLength(1);
          const link = messageLinks.at(0);
          expect(link.textContent).toBe('example site');
          expect(link.getAttribute('href')).toBe('https://example.com');
        });

        it('creates multiple links', () => {
          alert = createAlert({
            message:
              'Read more at %{exampleLinkStart}example site%{exampleLinkEnd}, or on %{docsLinkStart}the documentation%{docsLinkEnd}.',
            messageLinks: {
              exampleLink: 'https://example.com',
              docsLink: 'https://docs.example.com',
            },
          });
          const messageLinks = findAlertMessageLinks();

          expect(messageLinks).toHaveLength(2);
          const [firstLink, secondLink] = messageLinks;
          expect(firstLink.textContent).toBe('example site');
          expect(firstLink.getAttribute('href')).toBe('https://example.com');
          expect(secondLink.textContent).toBe('the documentation');
          expect(secondLink.getAttribute('href')).toBe('https://docs.example.com');
        });

        it('allows passing more props to gl-link', () => {
          alert = createAlert({
            message: 'Read more at %{exampleLinkStart}example site%{exampleLinkEnd}.',
            messageLinks: {
              exampleLink: {
                href: 'https://example.com',
                target: '_blank',
              },
            },
          });
          const messageLinks = findAlertMessageLinks();

          expect(messageLinks).toHaveLength(1);
          const link = messageLinks.at(0);
          expect(link.textContent).toBe('example site');
          expect(link.getAttribute('href')).toBe('https://example.com');
          expect(link.getAttribute('target')).toBe('_blank');
        });

        it('does not create any links when given an empty messageLinks object', () => {
          alert = createAlert({
            message: 'Read more at %{exampleLinkStart}example site%{exampleLinkEnd}.',
            messageLinks: {},
          });
          const messageLinks = findAlertMessageLinks();

          expect(messageLinks).toHaveLength(0);
        });
      });

      describe('when rendered as HTML', () => {
        const findMessageHTML = () => document.querySelector('.gl-alert-body div').innerHTML;
        const message =
          'error: <a href="https://documentation.com/further-information">learn more</a>';

        it('renders the given message as HTML', () => {
          alert = createAlert({
            message,
            renderMessageHTML: true,
          });

          expect(findMessageHTML()).toBe(message);
        });

        it('sanitizes the given message', () => {
          expect(sanitize).not.toHaveBeenCalled();

          createAlert({
            message,
            renderMessageHTML: true,
          });

          expect(sanitize).toHaveBeenCalledTimes(1);
          expect(sanitize).toHaveBeenCalledWith(message, {
            ALLOWED_TAGS: ['a'],
            ALLOWED_ATTR: ['href', 'rel', 'target'],
          });
        });
      });
    });
  });
});
