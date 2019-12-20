import AddSshKeyValidation from '../../../app/assets/javascripts/profile/add_ssh_key_validation';

describe('AddSshKeyValidation', () => {
  describe('submit', () => {
    it('returns true if isValid is true', () => {
      const addSshKeyValidation = new AddSshKeyValidation({});
      jest.spyOn(AddSshKeyValidation, 'isPublicKey').mockReturnValue(true);

      expect(addSshKeyValidation.submit()).toBeTruthy();
    });

    it('calls preventDefault and toggleWarning if isValid is false', () => {
      const addSshKeyValidation = new AddSshKeyValidation({});
      const event = {
        preventDefault: jest.fn(),
      };
      jest.spyOn(AddSshKeyValidation, 'isPublicKey').mockReturnValue(false);
      jest.spyOn(addSshKeyValidation, 'toggleWarning').mockImplementation(() => {});

      addSshKeyValidation.submit(event);

      expect(event.preventDefault).toHaveBeenCalled();
      expect(addSshKeyValidation.toggleWarning).toHaveBeenCalledWith(true);
    });
  });

  describe('toggleWarning', () => {
    it('shows warningElement and hides originalSubmitElement if isVisible is true', () => {
      const warningElement = document.createElement('div');
      const originalSubmitElement = document.createElement('div');
      warningElement.classList.add('hide');

      const addSshKeyValidation = new AddSshKeyValidation(
        {},
        warningElement,
        originalSubmitElement,
      );
      addSshKeyValidation.toggleWarning(true);

      expect(warningElement.classList.contains('hide')).toBeFalsy();
      expect(originalSubmitElement.classList.contains('hide')).toBeTruthy();
    });

    it('hides warningElement and shows originalSubmitElement if isVisible is false', () => {
      const warningElement = document.createElement('div');
      const originalSubmitElement = document.createElement('div');
      originalSubmitElement.classList.add('hide');

      const addSshKeyValidation = new AddSshKeyValidation(
        {},
        warningElement,
        originalSubmitElement,
      );
      addSshKeyValidation.toggleWarning(false);

      expect(warningElement.classList.contains('hide')).toBeTruthy();
      expect(originalSubmitElement.classList.contains('hide')).toBeFalsy();
    });
  });

  describe('isPublicKey', () => {
    it('returns false if probably invalid public ssh key', () => {
      expect(AddSshKeyValidation.isPublicKey('nope')).toBeFalsy();
    });

    it('returns true if probably valid public ssh key', () => {
      expect(AddSshKeyValidation.isPublicKey('ssh-')).toBeTruthy();
      expect(AddSshKeyValidation.isPublicKey('ecdsa-sha2-')).toBeTruthy();
    });
  });
});
