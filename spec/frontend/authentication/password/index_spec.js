import { nextTick } from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initPasswordInput } from '~/authentication/password/index';

describe('initPasswordInput', () => {
  const findInput = () => document.querySelector('.gl-form-password-input-field');

  const mountFixture = (overrides = {}) => {
    const attrs = {
      'data-id': 'user_password',
      'data-name': 'user[password]',
      'data-title': 'Choose a strong password',
      'data-minimum-password-length': '8',
      'data-testid': 'password-field',
      'data-track-action-for-errors': 'submit',
      'data-autocomplete': 'new-password',
      ...overrides,
    };
    const attrsString = Object.entries(attrs)
      .filter(([, value]) => value !== undefined)
      .map(([key, value]) => `${key}="${value}"`)
      .join(' ');

    setHTMLFixture(`<form><input class="js-password" ${attrsString} /></form>`);
    initPasswordInput();
    return nextTick();
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  it('mounts GlFormPasswordInput and forwards the hook classes and attributes to the inner input', async () => {
    await mountFixture();

    const input = findInput();

    expect(input).not.toBe(null);
    expect(input.classList).toContain('js-password-complexity-validation');
    expect(input.classList).toContain('js-track-error');
    expect(input.getAttribute('id')).toBe('user_password');
    expect(input.getAttribute('name')).toBe('user[password]');
    expect(input.getAttribute('title')).toBe('Choose a strong password');
    expect(input.getAttribute('minlength')).toBe('8');
    expect(input.getAttribute('autocomplete')).toBe('new-password');
    expect(input.dataset.testid).toBe('password-field');
    expect(input.dataset.trackActionForErrors).toBe('submit');
  });

  it('defaults autocomplete to current-password when the attribute is absent', async () => {
    await mountFixture({ 'data-autocomplete': undefined });

    expect(findInput().getAttribute('autocomplete')).toBe('current-password');
  });

  it('requires the input by default and can be disabled through the dataset', async () => {
    await mountFixture();
    expect(findInput().required).toBe(true);
    expect(findInput().disabled).toBe(false);

    resetHTMLFixture();

    await mountFixture({ 'data-required': 'false', 'data-disabled': 'true' });
    expect(findInput().required).toBe(false);
    expect(findInput().disabled).toBe(true);
  });

  it('anchors the injected field error after the whole field', async () => {
    await mountFixture();

    const anchor = document.querySelector('.gl-field-error-anchor');

    expect(anchor.nextElementSibling).toBe(document.querySelector('p.gl-field-error'));
  });
});
