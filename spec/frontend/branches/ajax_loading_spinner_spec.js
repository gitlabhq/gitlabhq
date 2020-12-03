import AjaxLoadingSpinner from '~/branches/ajax_loading_spinner';

describe('Ajax Loading Spinner', () => {
  let ajaxLoadingSpinnerElement;
  let fauxEvent;
  beforeEach(() => {
    document.body.innerHTML = `
    <div>
    <a class="js-ajax-loading-spinner"
       data-remote
       href="http://goesnowhere.nothing/whereami">
       Remove me
    </a></div>`;
    AjaxLoadingSpinner.init();
    ajaxLoadingSpinnerElement = document.querySelector('.js-ajax-loading-spinner');
    fauxEvent = { target: ajaxLoadingSpinnerElement };
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('`ajaxBeforeSend` event handler sets current icon to spinner and disables link', () => {
    expect(ajaxLoadingSpinnerElement.parentNode.querySelector('.gl-spinner')).toBeNull();
    expect(ajaxLoadingSpinnerElement.classList.contains('hidden')).toBe(false);

    AjaxLoadingSpinner.ajaxBeforeSend(fauxEvent);

    expect(ajaxLoadingSpinnerElement.parentNode.querySelector('.gl-spinner')).not.toBeNull();
    expect(ajaxLoadingSpinnerElement.classList.contains('hidden')).toBe(true);
  });
});
