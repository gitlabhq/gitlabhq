import $ from 'jquery';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import {
  REPO_BLOB_LOAD_VIEWER_START,
  REPO_BLOB_LOAD_VIEWER_FINISH,
  REPO_BLOB_LOAD_VIEWER,
  REPO_BLOB_SWITCH_TO_VIEWER_START,
  REPO_BLOB_SWITCH_VIEWER,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { fixTitle } from '~/tooltips';
import axios from '~/lib/utils/axios_utils';
import { handleLocationHash } from '~/lib/utils/common_utils';
import eventHub from '~/notes/event_hub';

const loadRichBlobViewer = (type) => {
  switch (type) {
    case 'notebook':
      return import(/* webpackChunkName: 'notebook_viewer' */ '../notebook_viewer');
    case 'openapi':
      return import(/* webpackChunkName: 'openapi_viewer' */ '../openapi_viewer');
    case 'csv':
      return import(/* webpackChunkName: 'csv_viewer' */ '../csv_viewer');
    case 'pdf':
      return import(/* webpackChunkName: 'pdf_viewer' */ '../pdf_viewer');
    case 'sketch':
      return import(/* webpackChunkName: 'sketch_viewer' */ '../sketch_viewer');
    case 'stl':
      return import(/* webpackChunkName: 'stl_viewer' */ '../stl_viewer');
    default:
      return Promise.resolve();
  }
};

const loadViewer = (viewerParam) => {
  const viewer = viewerParam;
  const { url } = viewer.dataset;

  if (!url || viewer.dataset.loaded || viewer.dataset.loading) {
    return Promise.resolve(viewer);
  }

  viewer.dataset.loading = 'true';

  return axios.get(url).then(({ data }) => {
    // eslint-disable-next-line no-unsanitized/property
    viewer.innerHTML = data.html;

    window.requestIdleCallback(() => {
      delete viewer.dataset.loading;
    });

    return viewer;
  });
};

export const initAuxiliaryViewer = () => {
  const auxiliaryViewer = document.querySelector('.blob-viewer[data-type="auxiliary"]');
  if (!auxiliaryViewer) return;

  loadViewer(auxiliaryViewer);
};

export const handleBlobRichViewer = (viewer, type) => {
  if (!viewer || !type) return;

  loadRichBlobViewer(type)
    .then((module) => module?.default(viewer))
    .catch((error) => {
      createAlert({
        message: __('Error loading file viewer.'),
      });
      throw error;
    });
};

export class BlobViewer {
  constructor() {
    performanceMarkAndMeasure({
      mark: REPO_BLOB_LOAD_VIEWER_START,
    });
    const viewer = document.querySelector('.blob-viewer[data-type="rich"]');
    const type = viewer?.dataset?.richType;
    initAuxiliaryViewer();

    handleBlobRichViewer(viewer, type);

    this.initMainViewers();
  }

  initMainViewers() {
    this.$fileHolder = $('.file-holder');
    if (!this.$fileHolder.length) return;

    this.switcher = document.querySelector('.js-blob-viewer-switcher');
    this.switcherBtns = document.querySelectorAll('.js-blob-viewer-switch-btn');
    this.copySourceBtn = document.querySelector('.js-copy-blob-source-btn');
    this.copySourceBtnTooltip = document.querySelector('.js-copy-blob-source-btn-tooltip');

    this.simpleViewer = this.$fileHolder[0].querySelector('.blob-viewer[data-type="simple"]');
    this.richViewer = this.$fileHolder[0].querySelector('.blob-viewer[data-type="rich"]');

    this.initBindings();

    this.switchToInitialViewer();
  }

  switchToInitialViewer() {
    const initialViewer = this.$fileHolder[0].querySelector('.blob-viewer:not(.hidden)');
    let initialViewerName = initialViewer.dataset.type;

    if (this.switcher && window.location.hash.indexOf('#L') === 0) {
      initialViewerName = 'simple';
    }

    this.switchToViewer(initialViewerName);
  }

  initBindings() {
    if (this.switcherBtns.length) {
      Array.from(this.switcherBtns).forEach((el) => {
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

    this.switchToViewer(target.dataset.viewer);
  }

  toggleCopyButtonState() {
    if (!this.copySourceBtn) return;
    if (this.simpleViewer.dataset.loaded) {
      this.copySourceBtnTooltip.setAttribute('title', __('Copy file contents'));
      this.copySourceBtn.classList.remove('disabled');
    } else if (this.activeViewer === this.simpleViewer) {
      this.copySourceBtnTooltip.setAttribute(
        'title',
        __('Wait for the file to load to copy its contents'),
      );
      this.copySourceBtn.classList.add('disabled');
    } else {
      this.copySourceBtnTooltip.setAttribute(
        'title',
        __('Switch to the source to copy the file contents'),
      );
      this.copySourceBtn.classList.add('disabled');
    }

    fixTitle($(this.copySourceBtnTooltip));
  }

  switchToViewer(name) {
    performanceMarkAndMeasure({
      mark: REPO_BLOB_SWITCH_TO_VIEWER_START,
    });
    const newViewer = this.$fileHolder[0].querySelector(`.blob-viewer[data-type='${name}']`);
    if (this.activeViewer === newViewer) return;

    const oldButton = document.querySelector('.js-blob-viewer-switch-btn.selected');
    const newButton = document.querySelector(`.js-blob-viewer-switch-btn[data-viewer='${name}']`);
    const oldViewer = this.$fileHolder[0].querySelector(`.blob-viewer:not([data-type='${name}'])`);

    if (oldButton) {
      oldButton.classList.remove('selected');
    }

    if (newButton) {
      newButton.classList.add('selected');
      newButton.blur();
    }

    if (oldViewer) {
      oldViewer.classList.add('hidden');
    }

    newViewer.classList.remove('hidden');

    this.activeViewer = newViewer;

    this.toggleCopyButtonState();
    loadViewer(newViewer)
      .then((viewer) => {
        renderGFM(viewer);
        window.requestIdleCallback(() => {
          this.$fileHolder.trigger('highlight:line');
          handleLocationHash();

          // eslint-disable-next-line no-param-reassign
          viewer.dataset.loaded = 'true';
          this.toggleCopyButtonState();
          eventHub.$emit('showBlobInteractionZones', viewer.dataset.path);
        });

        performanceMarkAndMeasure({
          mark: REPO_BLOB_LOAD_VIEWER_FINISH,
          measures: [
            {
              name: REPO_BLOB_LOAD_VIEWER,
              start: REPO_BLOB_LOAD_VIEWER_START,
            },
            {
              name: REPO_BLOB_SWITCH_VIEWER,
              start: REPO_BLOB_SWITCH_TO_VIEWER_START,
            },
          ],
        });
      })
      .catch(() =>
        createAlert({
          message: __('Error loading viewer'),
        }),
      );
  }
}
