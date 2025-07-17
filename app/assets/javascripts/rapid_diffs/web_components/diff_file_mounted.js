export const createDiffFileMounted = (appContext) => {
  return class extends HTMLElement {
    connectedCallback() {
      // this context is injected into the DiffFile component
      this.parentElement.mount(appContext);
    }
  };
};
