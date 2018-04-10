import $ from 'jquery';
import Flash from '../../flash';
import { handleLocationHash } from '../../lib/utils/common_utils';
import axios from '../../lib/utils/axios_utils';

export default class BlobViewer {
  constructor() {
    BlobViewer.initAuxiliaryViewer();
    BlobViewer.initRichViewer();

    this.initMainViewers();
  }

  static initAuxiliaryViewer() {
    const auxiliaryViewer = document.querySelector('.blob-viewer[data-type="auxiliary"]');
    if (!auxiliaryViewer) return;

    BlobViewer.loadViewer(auxiliaryViewer);
  }

  static initRichViewer() {
    const viewer = document.querySelector('.blob-viewer[data-type="rich"]');
    if (!viewer || !viewer.dataset.richType) return;

    const initViewer = promise => promise
      .then(module => module.default(viewer))
      .catch((error) => {
        Flash('Error loading file viewer.');
        throw error;
      });

    switch (viewer.dataset.richType) {
      case 'balsamiq':
        initViewer(import(/* webpackChunkName: 'balsamiq_viewer' */ '../balsamiq_viewer'));
        break;
      case 'notebook':
        initViewer(import(/* webpackChunkName: 'notebook_viewer' */ '../notebook_viewer'));
        break;
      case 'pdf':
        initViewer(import(/* webpackChunkName: 'pdf_viewer' */ '../pdf_viewer'));
        break;
      case 'sketch':
        initViewer(import(/* webpackChunkName: 'sketch_viewer' */ '../sketch_viewer'));
        break;
      case 'stl':
        initViewer(import(/* webpackChunkName: 'stl_viewer' */ '../stl_viewer'));
        break;
      default:
        break;
    }
  }

  initMainViewers() {
    this.$fileHolder = $('.file-holder');
    if (!this.$fileHolder.length) return;

    this.switcher = document.querySelector('.js-blob-viewer-switcher');
    this.switcherBtns = document.querySelectorAll('.js-blob-viewer-switch-btn');
    this.copySourceBtn = document.querySelector('.js-copy-blob-source-btn');

    this.simpleViewer = this.$fileHolder[0].querySelector('.blob-viewer[data-type="simple"]');
    this.richViewer = this.$fileHolder[0].querySelector('.blob-viewer[data-type="rich"]');

    this.initBindings();

    this.switchToInitialViewer();
  }

  switchToInitialViewer() {
    const initialViewer = this.$fileHolder[0].querySelector('.blob-viewer:not(.hidden)');
    let initialViewerName = initialViewer.getAttribute('data-type');

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

  switchToViewer(name) {
    const newViewer = this.$fileHolder[0].querySelector(`.blob-viewer[data-type='${name}']`);
    if (this.activeViewer === newViewer) return;

    const oldButton = document.querySelector('.js-blob-viewer-switch-btn.active');
    const newButton = document.querySelector(`.js-blob-viewer-switch-btn[data-viewer='${name}']`);
    const oldViewer = this.$fileHolder[0].querySelector(`.blob-viewer:not([data-type='${name}'])`);

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

      this.$fileHolder.trigger('highlight:line');
      handleLocationHash();

      this.toggleCopyButtonState();
    })
    .catch(() => new Flash('Error loading viewer'));
  }

  static loadViewer(viewerParam) {
    const viewer = viewerParam;
    const url = viewer.getAttribute('data-url');

    if (!url || viewer.getAttribute('data-loaded') || viewer.getAttribute('data-loading')) {
      return Promise.resolve(viewer);
    }

    viewer.setAttribute('data-loading', 'true');

    return axios.get(url)
      .then(({ data }) => {
        viewer.innerHTML = data.html;
        viewer.setAttribute('data-loaded', 'true');

        return viewer;
      });
  }
}
