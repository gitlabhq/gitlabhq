import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initPersonalAccessTokenFormValidation } from '~/pages/import/github/new/init_personal_access_token_form_validation';

describe('initPersonalAccessTokenFormValidation', () => {
  let patField;
  let patValidation;
  let authenticateButton;

  const triggerInput = () => {
    patField.value = 'ab';
    patField.dispatchEvent(new Event('input'));
  };

  beforeEach(() => {
    setHTMLFixture(`
    <div>
      <div class="form-group gl-form-group">
        <label class="col-form-label" for="personal_access_token">Personal access token</label>
        <input type="password" name="personal_access_token" id="personal_access_token" value="" class="form-control gl-form-input js-import-github-pat-field">
        <p class="invalid-feedback js-import-github-pat-validation">Personal access token is required.</p>
      </div>
      <div class="form-actions">
        <button class="js-import-github-pat-authenticate" type="submit">Authenticate</button>
      </div>
    </div>
    `);

    patField = document.querySelector('.js-import-github-pat-field');
    patValidation = document.querySelector('.js-import-github-pat-validation');
    authenticateButton = document.querySelector('.js-import-github-pat-authenticate');

    initPersonalAccessTokenFormValidation();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('shows error paragraph when PAT is missing', () => {
    authenticateButton.click();

    expect(patField.classList.contains('is-invalid')).toBe(true);
    expect(patValidation.classList.contains('!gl-block')).toBe(true);
  });

  it('removes the error paragraph when user starts typing in the PAT field', () => {
    authenticateButton.click();

    expect(patField.classList.contains('is-invalid')).toBe(true);
    expect(patValidation.classList.contains('!gl-block')).toBe(true);

    triggerInput();

    expect(patField.classList.contains('is-invalid')).toBe(false);
    expect(patValidation.classList.contains('!gl-block')).toBe(false);
  });

  it(`does not show "PAT is required" error when the field is filled`, () => {
    triggerInput();
    authenticateButton.click();

    expect(patField.classList.contains('is-invalid')).toBe(false);
    expect(patValidation.classList.contains('!gl-block')).toBe(false);
  });
});
