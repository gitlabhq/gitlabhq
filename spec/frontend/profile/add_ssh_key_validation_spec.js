import AddSshKeyValidation from '~/profile/add_ssh_key_validation';

describe('AddSshKeyValidation', () => {
  describe('submit', () => {
    it('returns true if isValid is true', () => {
      const addSshKeyValidation = new AddSshKeyValidation([], {});
      jest.spyOn(addSshKeyValidation, 'isPublicKey').mockReturnValue(true);

      expect(addSshKeyValidation.submit()).toBe(true);
    });

    it('calls preventDefault and toggleWarning if isValid is false', () => {
      const addSshKeyValidation = new AddSshKeyValidation([], {});
      const event = {
        preventDefault: jest.fn(),
      };
      jest.spyOn(addSshKeyValidation, 'isPublicKey').mockReturnValue(false);
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
        [],
        {},
        warningElement,
        originalSubmitElement,
      );
      addSshKeyValidation.toggleWarning(true);

      expect(warningElement.classList.contains('hide')).toBe(false);
      expect(originalSubmitElement.classList.contains('hide')).toBe(true);
    });

    it('hides warningElement and shows originalSubmitElement if isVisible is false', () => {
      const warningElement = document.createElement('div');
      const originalSubmitElement = document.createElement('div');
      originalSubmitElement.classList.add('hide');

      const addSshKeyValidation = new AddSshKeyValidation(
        [],
        {},
        warningElement,
        originalSubmitElement,
      );
      addSshKeyValidation.toggleWarning(false);

      expect(warningElement.classList.contains('hide')).toBe(true);
      expect(originalSubmitElement.classList.contains('hide')).toBe(false);
    });
  });

  describe('isPublicKey', () => {
    it('returns false if value begins with an algorithm name that is unsupported', () => {
      const addSshKeyValidation = new AddSshKeyValidation(['ssh-rsa', 'ssh-algorithm'], {});

      expect(addSshKeyValidation.isPublicKey('nope key')).toBe(false);
      expect(addSshKeyValidation.isPublicKey('ssh- key')).toBe(false);
      expect(addSshKeyValidation.isPublicKey('unsupported-ssh-rsa key')).toBe(false);
    });

    it('returns true if value begins with an algorithm name that is supported', () => {
      const addSshKeyValidation = new AddSshKeyValidation(['ssh-rsa', 'ssh-algorithm'], {});

      expect(addSshKeyValidation.isPublicKey('ssh-rsa key')).toBe(true);
      expect(addSshKeyValidation.isPublicKey('ssh-algorithm key')).toBe(true);
    });
  });
});
