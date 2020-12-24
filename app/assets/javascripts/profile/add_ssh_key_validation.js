export default class AddSshKeyValidation {
  constructor(inputElement, warningElement, originalSubmitElement, confirmSubmitElement) {
    this.inputElement = inputElement;
    this.form = inputElement.form;

    this.warningElement = warningElement;

    this.originalSubmitElement = originalSubmitElement;
    this.confirmSubmitElement = confirmSubmitElement;

    this.isValid = false;
  }

  register() {
    this.form.addEventListener('submit', (event) => this.submit(event));

    this.confirmSubmitElement.addEventListener('click', () => {
      this.isValid = true;
      this.form.submit();
    });

    this.inputElement.addEventListener('input', () => this.toggleWarning(false));
  }

  submit(event) {
    this.isValid = AddSshKeyValidation.isPublicKey(this.inputElement.value);

    if (this.isValid) return true;

    event.preventDefault();
    this.toggleWarning(true);
    return false;
  }

  toggleWarning(isVisible) {
    this.warningElement.classList.toggle('hide', !isVisible);
    this.originalSubmitElement.classList.toggle('hide', isVisible);
  }

  static isPublicKey(value) {
    return /^(ssh|ecdsa-sha2)-/.test(value);
  }
}
