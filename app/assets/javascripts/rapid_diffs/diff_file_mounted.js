export class DiffFileMounted extends HTMLElement {
  connectedCallback() {
    this.parentElement.mount();
  }
}
