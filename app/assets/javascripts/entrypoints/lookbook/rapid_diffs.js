import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';

customElements.define('diff-file', DiffFile);
customElements.define(
  'diff-file-mounted',
  class extends HTMLElement {
    connectedCallback() {
      this.parentElement.mount({
        adapterConfig: VIEWER_ADAPTERS,
        observe: () => {},
      });
    }
  },
);

document.querySelector('[data-rapid-diffs]').addEventListener('click', (event) => {
  const diffFile = event.target.closest('diff-file');
  if (!diffFile) return;
  diffFile.onClick(event);
});
