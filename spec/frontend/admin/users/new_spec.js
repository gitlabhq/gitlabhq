import {
  setupInternalUserRegexHandler,
  ID_USER_EMAIL,
  ID_USER_EXTERNAL,
  ID_WARNING,
} from '~/admin/users/new';

describe('admin/users/new', () => {
  const FIXTURE = 'admin/users/new_with_internal_user_regex.html';

  let elExternal;
  let elUserEmail;
  let elWarningMessage;

  beforeEach(() => {
    loadFixtures(FIXTURE);
    setupInternalUserRegexHandler();

    elExternal = document.getElementById(ID_USER_EXTERNAL);
    elUserEmail = document.getElementById(ID_USER_EMAIL);
    elWarningMessage = document.getElementById(ID_WARNING);

    elExternal.checked = true;
  });

  const changeEmail = (val) => {
    elUserEmail.value = val;
    elUserEmail.dispatchEvent(new Event('input'));
  };

  const hasHiddenWarning = () => elWarningMessage.classList.contains('hidden');

  describe('Behaviour of userExternal checkbox', () => {
    it('hides warning by default', () => {
      expect(hasHiddenWarning()).toBe(true);
    });

    describe('when matches email as internal', () => {
      beforeEach(() => {
        changeEmail('test@');
      });

      it('has external unchecked', () => {
        expect(elExternal.checked).toBe(false);
      });

      it('shows warning', () => {
        expect(hasHiddenWarning()).toBe(false);
      });

      describe('when external is checked again', () => {
        beforeEach(() => {
          elExternal.dispatchEvent(new Event('change'));
        });

        it('hides warning', () => {
          expect(hasHiddenWarning()).toBe(true);
        });
      });
    });

    describe('when matches emails as external', () => {
      beforeEach(() => {
        changeEmail('test.ext@');
      });

      it('has external checked', () => {
        expect(elExternal.checked).toBe(true);
      });

      it('hides warning', () => {
        expect(hasHiddenWarning()).toBe(true);
      });
    });
  });
});
