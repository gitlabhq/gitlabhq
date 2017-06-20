/* global Flash */
export default class BlobViewer {
  constructor(container = document.body, type = 'blob') {
    this.container = container;
    this.type = type;

    this.initAuxiliaryViewer();

    this.initMainViewers();
  }

  initAuxiliaryViewer() {
    const auxiliaryViewer = this.viewerForName('auxiliary', this.container);
    if (!auxiliaryViewer) return;

    BlobViewer.loadViewer(auxiliaryViewer);
  }

  initMainViewers() {
    this.fileHolder = this.container.classList.contains('file-holder') ? this.container : this.container.querySelector('.file-holder');
    if (!this.fileHolder) return;

    this.switcher = this.container.querySelector(`.js-${this.type}-viewer-switcher`);
    this.switcherBtns = this.container.querySelectorAll(`.js-${this.type}-viewer-switch-btn`);
    this.loadBtns = this.container.querySelectorAll(`.js-${this.type}-viewer-load-btn`);
    this.copySourceBtn = this.container.querySelector('.js-copy-blob-source-btn');

    this.simpleViewer = this.viewerForName('simple');
    this.richViewer = this.viewerForName('rich');

    this.initBindings();

    this.switchToInitialViewer();
  }

  switchToInitialViewer() {
    const locationHash = gl.utils.getLocationHash();
    let initialViewer = this.fileHolder.querySelector(`.${this.type}-viewer:not(.hidden)`);

    if (this.switcher && locationHash && locationHash.indexOf('L') === 0) {
      initialViewer = this.simpleViewer;
    }

    this.switchToViewer(initialViewer);
  }

  initBindings() {
    if (this.switcherBtns.length) {
      Array.from(this.switcherBtns)
        .forEach((el) => {
          el.addEventListener('click', this.switchViewHandler.bind(this));
        });
    }

    if (this.loadBtns.length) {
      Array.from(this.loadBtns)
        .forEach((el) => {
          el.addEventListener('click', this.loadViewHandler.bind(this));
        });
    }

    if (this.copySourceBtn) {
      this.copySourceBtn.addEventListener('click', () => {
        if (this.copySourceBtn.classList.contains('disabled')) return this.copySourceBtn.blur();

        return this.switchToViewer(this.simpleViewer);
      });
    }
  }

  switchViewHandler(e) {
    const target = e.currentTarget;

    e.preventDefault();

    const viewer = this.viewerForName(target.getAttribute('data-viewer'));
    if (!viewer) return;
    this.switchToViewer(viewer);
  }

  loadViewHandler(e) {
    const target = e.currentTarget;

    e.preventDefault();

    const viewer = this.viewerForName(target.getAttribute('data-viewer'));
    if (!viewer) return;
    this.loadViewer(viewer, true);
  }

  viewerForName(name, container = this.fileHolder) {
    return container.querySelector(`.${this.type}-viewer[data-type='${name}']`);
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

  switchToViewer(newViewer) {
    if (this.activeViewer === newViewer) return;

    const name = newViewer.getAttribute('data-type');
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

    this.loadViewer(newViewer);
  }

  loadViewer(viewer, force = false) {
    BlobViewer.loadViewer(viewer, force)
    .then((viewer) => {
      $(viewer).renderGFM();

      $(this.fileHolder).trigger('highlight:line');
      gl.utils.handleLocationHash();

      this.toggleCopyButtonState();
    })
    .catch(() => new Flash('Error loading viewer'));
  }

  static loadViewer(viewerParam, force = false) {
    const viewer = viewerParam;
    const url = viewer.getAttribute('data-url');

    return new Promise((resolve, reject) => {
      if (!url || viewer.getAttribute('data-loaded') || viewer.getAttribute('data-loading')) {
        resolve(viewer);
        return;
      }

      if (viewer.getAttribute('data-autoload') === 'false' && !force) {
        resolve(viewer);
        return;
      }

      viewer.setAttribute('data-loading', 'true');

      const fileContent = viewer.querySelector('.file-content');
      const loadingIndicator = viewer.querySelector('.file-loading');
      if (fileContent) fileContent.classList.add('hidden');
      if (loadingIndicator) loadingIndicator.classList.remove('hidden');

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
