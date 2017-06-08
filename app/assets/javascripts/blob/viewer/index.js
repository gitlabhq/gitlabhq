/* global Flash */
export default class BlobViewer {
  constructor() {
    this.switcher = document.querySelector('.js-blob-viewer-switcher');
    this.switcherBtns = document.querySelectorAll('.js-blob-viewer-switch-btn');
    this.copySourceBtn = document.querySelector('.js-copy-blob-source-btn');
    this.simpleViewer = document.querySelector('.blob-viewer[data-type="simple"]');
    this.richViewer = document.querySelector('.blob-viewer[data-type="rich"]');
    this.$fileHolder = $('.file-holder');

    let initialViewerName = document.querySelector('.blob-viewer:not(.hidden)').getAttribute('data-type');

    this.initBindings();

    if (this.switcher && location.hash.indexOf('#L') === 0) {
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

  loadViewer(viewerParam) {
    const viewer = viewerParam;
    const url = viewer.getAttribute('data-url');

    if (!url || viewer.getAttribute('data-loaded') || viewer.getAttribute('data-loading')) {
      return;
    }

    viewer.setAttribute('data-loading', 'true');

    $.ajax({
      url,
      dataType: 'JSON',
    })
    .fail(() => new Flash('Error loading source view'))
    .done((data) => {
      viewer.innerHTML = data.html;
      $(viewer).renderGFM();

      viewer.setAttribute('data-loaded', 'true');

      this.$fileHolder.trigger('highlight:line');
      gl.utils.handleLocationHash();

      this.toggleCopyButtonState();
    });
  }

  switchToViewer(name) {
    const newViewer = document.querySelector(`.blob-viewer[data-type='${name}']`);
    if (this.activeViewer === newViewer) return;

    const oldButton = document.querySelector('.js-blob-viewer-switch-btn.active');
    const newButton = document.querySelector(`.js-blob-viewer-switch-btn[data-viewer='${name}']`);
    const oldViewer = document.querySelector(`.blob-viewer:not([data-type='${name}'])`);

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
}
