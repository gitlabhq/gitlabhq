/* global Flash */
export default class BlobViewer {
  constructor(container = document.body, type = 'blob') {
    this.container = container;
    this.type = type;

    this.initAuxiliaryViewer();

    this.initMainViewers();
  }

  initAuxiliaryViewer() {
    const auxiliaryViewer = this.container.querySelector(`.${this.type}-viewer[data-type="auxiliary"]`);
    if (!auxiliaryViewer) return;

    BlobViewer.loadViewer(auxiliaryViewer);
  }

  initMainViewers() {
    this.fileHolder = this.container.classList.contains('file-holder') ? this.container : this.container.querySelector('.file-holder');
    if (!this.fileHolder) return;

    this.switcher = this.container.querySelector(`.js-${this.type}-viewer-switcher`);
    this.switcherBtns = this.container.querySelectorAll(`.js-${this.type}-viewer-switch-btn`);
    this.copySourceBtn = this.container.querySelector('.js-copy-blob-source-btn');

    this.simpleViewer = this.fileHolder.querySelector(`.${this.type}-viewer[data-type="simple"]`);
    this.richViewer = this.fileHolder.querySelector(`.${this.type}-viewer[data-type="rich"]`);

    this.initBindings();

    this.switchToInitialViewer();
  }

  switchToInitialViewer() {
    const locationHash = gl.utils.getLocationHash();
    const initialViewer = this.fileHolder.querySelector(`.${this.type}-viewer:not(.hidden)`);
    const simpleLine = document.getElementById(locationHash);
    let initialViewerName = initialViewer.getAttribute('data-type');

    if (this.switcher && (simpleLine !== null || (locationHash && locationHash.indexOf('L') === 0))) {
      initialViewerName = 'simple';
    }

    this.switchToViewer(initialViewerName);
  }

  initBindings() {
    if (this.switcherBtns.length) {
      Array.from(this.switcherBtns)
        .forEach((el) => {
          el.addEventListener('click', this.switchViewHandler.bind(this));
        });
    }

    if (this.copySourceBtn) {
      this.copySourceBtn.addEventListener('click', () => {
        if (this.copySourceBtn.classList.contains('disabled')) return this.copySourceBtn.blur();

        return this.switchToViewer('simple');
      });
    }
  }

  switchViewHandler(e) {
    const target = e.currentTarget;

    e.preventDefault();

    this.switchToViewer(target.getAttribute('data-viewer'));
  }

  toggleCopyButtonState() {
    if (!this.copySourceBtn) return;

    if (this.simpleViewer.getAttribute('data-loaded')) {
      this.copySourceBtn.setAttribute('title', 'Copy source to clipboard');
      this.copySourceBtn.classList.remove('disabled');
    } else if (this.activeViewer === this.simpleViewer) {
      this.copySourceBtn.setAttribute('title', 'Wait for the source to load to copy it to the clipboard');
      this.copySourceBtn.classList.add('disabled');
    } else {
      this.copySourceBtn.setAttribute('title', 'Switch to the source to copy it to the clipboard');
      this.copySourceBtn.classList.add('disabled');
    }

    $(this.copySourceBtn).tooltip('fixTitle');
  }

  switchToViewer(name) {
    const newViewer = this.fileHolder.querySelector(`.${this.type}-viewer[data-type='${name}']`);
    if (this.activeViewer === newViewer) return;

    const oldButton = this.container.querySelector(`.js-${this.type}-viewer-switch-btn.active`);
    const newButton = this.container.querySelector(`.js-${this.type}-viewer-switch-btn[data-viewer='${name}']`);
    const oldViewer = this.fileHolder.querySelector(`.${this.type}-viewer:not([data-type='${name}'])`);

    if (oldButton) {
      oldButton.classList.remove('active');
    }

    if (newButton) {
      newButton.classList.add('active');
      newButton.blur();
    }

    if (oldViewer) {
      oldViewer.classList.add('hidden');
    }

    newViewer.classList.remove('hidden');

    this.activeViewer = newViewer;

    this.toggleCopyButtonState();

    BlobViewer.loadViewer(newViewer)
    .then((viewer) => {
      $(viewer).renderGFM();

      $(this.fileHolder).trigger('highlight:line');
      gl.utils.handleLocationHash();

      this.toggleCopyButtonState();
    })
    .catch(() => new Flash('Error loading viewer'));
  }

  static loadViewer(viewerParam) {
    const viewer = viewerParam;
    const url = viewer.getAttribute('data-url');

    return new Promise((resolve, reject) => {
      if (!url || viewer.getAttribute('data-loaded') || viewer.getAttribute('data-loading')) {
        resolve(viewer);
        return;
      }

      viewer.setAttribute('data-loading', 'true');

      $.ajax({
        url,
        dataType: 'JSON',
      })
      .fail(reject)
      .done((data) => {
        viewer.innerHTML = data.html;
        viewer.setAttribute('data-loaded', 'true');

        resolve(viewer);
      });
    });
  }
}
