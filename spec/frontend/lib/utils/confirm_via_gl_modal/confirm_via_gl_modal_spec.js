import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { confirmViaGlModal } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');

describe('confirmViaGlModal', () => {
  let el;

  afterEach(() => {
    el = undefined;
    resetHTMLFixture();
    jest.resetAllMocks();
  });

  const createElement = (html) => {
    setHTMLFixture(html);
    return document.body.firstChild;
  };

  it('returns confirmAction result', async () => {
    confirmAction.mockReturnValue(Promise.resolve(true));
    el = createElement(`<div/>`);

    await expect(confirmViaGlModal('', el)).resolves.toBe(true);
  });

  it('calls confirmAction with message', () => {
    el = createElement(`<div/>`);

    confirmViaGlModal('message', el);

    expect(confirmAction).toHaveBeenCalledWith('message', {});
  });

  it.each(['gl-sr-only', 'sr-only'])(
    `uses slot.%s contentText as primaryBtnText`,
    (srOnlyClass) => {
      el = createElement(
        `<a href="#"><span class="${srOnlyClass}">Delete merge request</span></a>`,
      );

      confirmViaGlModal('', el);

      expect(confirmAction).toHaveBeenCalledWith('', {
        primaryBtnText: 'Delete merge request',
      });
    },
  );

  it('uses `aria-label` value as `primaryBtnText`', () => {
    el = createElement(`<a aria-label="Delete merge request" href="#"></a>`);

    confirmViaGlModal('', el);

    expect(confirmAction).toHaveBeenCalledWith('', {
      primaryBtnText: 'Delete merge request',
    });
  });

  it.each([
    ['title', 'title', 'Delete?'],
    ['confirm-btn-variant', `primaryBtnVariant`, 'danger'],
  ])('uses data-%s value as confirmAction config', (dataKey, configKey, value) => {
    el = createElement(`<a data-${dataKey}="${value}" href="#"></a>`);

    confirmViaGlModal('message', el);

    expect(confirmAction).toHaveBeenCalledWith('message', { [configKey]: value });
  });

  it('uses message as modalHtmlMessage value when data-is-html-message is true', () => {
    el = createElement(`<a data-is-html-message="true" href="#"></a>`);
    const message = 'Hola mundo!';

    confirmViaGlModal(message, el);

    expect(confirmAction).toHaveBeenCalledWith(message, { modalHtmlMessage: message });
  });

  it('uses data-tracking-event attributes to prepare trackEventConfig', () => {
    el = createElement(
      `<a data-tracking-event-name="test_event" data-tracking-event-label="test_label" data-tracking-event-property="test_property" data-tracking-event-value="test_value" href="#"></a>`,
    );
    const message = 'Test message';

    confirmViaGlModal(message, el);

    expect(confirmAction).toHaveBeenCalledWith(message, {
      trackingEvent: {
        name: 'test_event',
        label: 'test_label',
        property: 'test_property',
        value: 'test_value',
      },
    });
  });
});
