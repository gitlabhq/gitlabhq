import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';
import { initCompareButtonLoading } from '~/merge_requests/init_compare_app';

jest.mock('~/loading_icon_for_legacy_js');

describe('init_compare_app', () => {
  describe('initCompareButtonLoading', () => {
    let form;
    let submitButton;

    const createForm = () => {
      form = document.createElement('form');
      form.classList.add('merge-request-form');

      submitButton = document.createElement('button');
      submitButton.type = 'submit';
      submitButton.classList.add(
        'js-compare-branches-button',
        'gl-button',
        'btn',
        'btn-md',
        'btn-confirm',
      );
      submitButton.innerHTML = '<span class="gl-button-text">Compare branches and continue</span>';

      form.appendChild(submitButton);
      document.body.appendChild(form);
    };

    beforeEach(() => {
      const fakeLoader = document.createElement('span');
      fakeLoader.classList.add('gl-spinner');
      loadingIconForLegacyJS.mockReturnValue(fakeLoader);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('does nothing when form is not present', () => {
      initCompareButtonLoading();

      expect(loadingIconForLegacyJS).not.toHaveBeenCalled();
    });

    it('does nothing when submit button is not present', () => {
      form = document.createElement('form');
      form.classList.add('merge-request-form');
      document.body.appendChild(form);

      initCompareButtonLoading();

      expect(loadingIconForLegacyJS).not.toHaveBeenCalled();
    });

    describe('when form and button are present', () => {
      beforeEach(() => {
        createForm();
        initCompareButtonLoading();
      });

      it('disables the button on form submit', () => {
        form.dispatchEvent(new Event('submit', { cancelable: true }));

        expect(submitButton.getAttribute('disabled')).toBe('disabled');
      });

      it('prepends a loading icon to the button on form submit', () => {
        form.dispatchEvent(new Event('submit', { cancelable: true }));

        expect(loadingIconForLegacyJS).toHaveBeenCalledWith({
          inline: true,
          size: 'sm',
          classes: ['gl-mr-3'],
        });
        expect(submitButton.firstChild.classList.contains('gl-spinner')).toBe(true);
      });

      it('does not add a second spinner if the button is already disabled', () => {
        form.dispatchEvent(new Event('submit', { cancelable: true }));
        form.dispatchEvent(new Event('submit', { cancelable: true }));

        expect(loadingIconForLegacyJS).toHaveBeenCalledTimes(1);
        expect(submitButton.querySelectorAll('.gl-spinner')).toHaveLength(1);
      });
    });
  });
});
