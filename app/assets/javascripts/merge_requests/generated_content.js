export class MergeRequestGeneratedContent {
  constructor({ editor } = {}) {
    this.warningElement = document.querySelector('.js-ai-description-warning');
    this.markdownEditor = editor;
    this.generatedContent = null;

    this.connectToDOM();
  }

  get hasEditor() {
    return Boolean(this.markdownEditor);
  }
  get hasWarning() {
    return Boolean(this.warningElement);
  }
  get canReplaceContent() {
    return this.hasEditor && Boolean(this.generatedContent);
  }

  connectToDOM() {
    let close;
    let cancel;
    let approve;

    if (this.hasWarning) {
      approve = this.warningElement.querySelector('.js-ai-override-description');
      cancel = this.warningElement.querySelector('.js-cancel-btn');
      close = this.warningElement.querySelector('.js-close-btn');

      approve.addEventListener('click', () => {
        this.replaceDescription();
        this.hideWarning();
      });

      cancel.addEventListener('click', () => this.hideWarning());
      close.addEventListener('click', () => this.hideWarning());
    }
  }

  setEditor(markdownEditor) {
    this.markdownEditor = markdownEditor;
  }
  setGeneratedContent(newContent) {
    this.generatedContent = newContent;
  }
  clearGeneratedContent() {
    this.generatedContent = null;
  }

  showWarning() {
    if (this.canReplaceContent) {
      this.warningElement?.classList.remove('hidden');
    }
  }
  hideWarning() {
    this.warningElement?.classList.add('hidden');
  }
  replaceDescription() {
    if (this.canReplaceContent) {
      this.markdownEditor.setValue(this.generatedContent);
      this.clearGeneratedContent();
    }
  }
}
