import { setHTMLFixture, resetHTMLFixture } from 'jest/__helpers__/fixtures';
import initFormUpdate from '~/pages/projects/merge_requests/edit/update_form';

describe('Update form state', () => {
  const submitEvent = new Event('submit', {
    bubbles: true,
    cancelable: true,
  });

  const submitForm = () => document.querySelector('.merge-request-form').dispatchEvent(submitEvent);
  const hiddenInputs = () => document.querySelectorAll('input[type="hidden"]');
  const checkboxes = () => document.querySelectorAll('.js-form-update');

  beforeEach(() => {
    setHTMLFixture(`
    <form class="merge-request-form">
        <div class="form-check">
            <input type="hidden" name="merge_request[force_remove_source_branch]" value="0" autocomplete="off">
            <input type="checkbox" name="merge_request[force_remove_source_branch]" id="merge_request_force_remove_source_branch" value="1" class="form-check-input js-form-update">
        </div>
        <div class="form-check">
            <input type="hidden" name="merge_request[squash]" value="0" autocomplete="off">
            <input type="checkbox" name="merge_request[squash]" id="merge_request_squash" value="1" class="form-check-input js-form-update">
        </div>
    </form>`);
    initFormUpdate();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('at initial state', () => {
    submitForm();
    expect(hiddenInputs()).toHaveLength(2);
  });

  it('when one element is checked', () => {
    checkboxes()[0].setAttribute('checked', true);
    submitForm();
    expect(hiddenInputs()).toHaveLength(1);
  });

  it('when all elements are checked', () => {
    checkboxes()[0].setAttribute('checked', true);
    checkboxes()[1].setAttribute('checked', true);
    submitForm();
    expect(hiddenInputs()).toHaveLength(0);
  });

  it('when checked and then unchecked', () => {
    checkboxes()[0].setAttribute('checked', true);
    checkboxes()[0].removeAttribute('checked');
    checkboxes()[1].setAttribute('checked', true);
    checkboxes()[1].removeAttribute('checked');
    submitForm();
    expect(hiddenInputs()).toHaveLength(2);
  });
});
