import { KeyMod, KeyCode, Emitter } from 'monaco-editor';
import { debounce } from 'lodash';
import { BLOB_PREVIEW_ERROR } from '~/blob_edit/constants';
import { createAlert } from '~/alert';
import { sanitize } from '~/lib/dompurify';
import axios from '~/lib/utils/axios_utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import {
  EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
  EXTENSION_MARKDOWN_PREVIEW_HIDE_ACTION_ID,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY,
  EXTENSION_MARKDOWN_PREVIEW_LABEL,
  EXTENSION_MARKDOWN_HIDE_PREVIEW_LABEL,
} from '../constants';

const fetchPreview = (text, previewMarkdownPath) => {
  return axios
    .post(previewMarkdownPath, {
      text,
    })
    .then(({ data }) => {
      return data.body;
    });
};

const setupDomElement = ({ injectToEl = null } = {}) => {
  const previewEl = document.createElement('div');
  previewEl.classList.add(EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS);
  previewEl.style.display = 'none';
  if (injectToEl) {
    injectToEl.appendChild(previewEl);
  }
  return previewEl;
};

export class EditorMarkdownPreviewExtension {
  static get extensionName() {
    return 'EditorMarkdownPreview';
  }

  onSetup(instance, setupOptions) {
    this.preview = {
      el: undefined,
      actions: {
        preview: undefined,
        hide: undefined,
      },
      shown: false,
      modelChangeListener: undefined,
      path: setupOptions.previewMarkdownPath,
      actionShowPreviewCondition: instance.createContextKey('toggleLivePreview', true),
      eventEmitter: new Emitter(),
    };
    this.toolbarButtons = [];

    this.setupPreviewAction(instance);

    const debouncedResizeHandler = debounce((entries) => {
      for (const entry of entries) {
        const { width: newInstanceWidth } = entry.contentRect;
        if (instance.markdownPreview?.shown) {
          const newWidth = newInstanceWidth * EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH;
          EditorMarkdownPreviewExtension.resizePreviewLayout(instance, newWidth);
        }
      }
    }, 50);

    this.resizeObserver = new ResizeObserver(debouncedResizeHandler);

    this.preview.eventEmitter.event(this.togglePreview.bind(this, instance));
  }

  onBeforeUnuse(instance) {
    this.cleanup(instance);
    const ids = this.toolbarButtons.map((item) => item.id);
    if (instance.toolbar) {
      instance.toolbar.removeItems(ids);
    }
  }

  cleanup(instance) {
    this.resizeObserver.disconnect();
    if (this.preview.modelChangeListener) {
      this.preview.modelChangeListener.dispose();
    }
    this.preview.actions.preview.dispose();
    this.preview.actions.hide.dispose();
    if (this.preview.shown) {
      this.togglePreviewPanel(instance);
      this.togglePreviewLayout(instance);
    }
    this.preview.shown = false;
  }

  static resizePreviewLayout(instance, width) {
    const { height } = instance.getLayoutInfo();
    instance.layout({ width, height });
  }

  togglePreviewLayout(instance) {
    const { width } = instance.getLayoutInfo();
    let newWidth;
    if (this.preview.shown) {
      // This means the preview is to be closed at the next step
      newWidth = width / EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH;
      this.resizeObserver.disconnect();
    } else {
      // The preview is hidden, but is in the process to be opened
      newWidth = width * EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH;
      this.resizeObserver.observe(instance.getContainerDomNode());
    }
    EditorMarkdownPreviewExtension.resizePreviewLayout(instance, newWidth);
  }

  togglePreviewPanel(instance) {
    const parentEl = instance.getDomNode().parentElement;
    const { el: previewEl } = this.preview;
    parentEl.classList.toggle(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS);

    if (previewEl.style.display === 'none') {
      // Show the preview panel
      this.fetchPreview(instance);
    } else {
      // Hide the preview panel
      previewEl.style.display = 'none';
    }
  }

  fetchPreview(instance) {
    const { el: previewEl } = this.preview;
    fetchPreview(instance.getValue(), this.preview.path)
      .then((data) => {
        previewEl.innerHTML = sanitize(data);
        previewEl.style.display = 'block';
        renderGFM(previewEl);
      })
      .catch(() => createAlert(BLOB_PREVIEW_ERROR));
  }

  setupPreviewAction(instance) {
    if (instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)) return;
    const actionBasis = {
      keybindings: [
        // eslint-disable-next-line no-bitwise
        KeyMod.chord(KeyMod.CtrlCmd | KeyMod.Shift | KeyCode.KEY_P),
      ],
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 1.5,
      // Method that will be executed when the action is triggered.
      // @param ed The editor instance is passed in as a convenience
      run(inst) {
        inst.togglePreview();
      },
    };

    this.preview.actions.preview = instance.addAction({
      ...actionBasis,
      id: EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
      label: EXTENSION_MARKDOWN_PREVIEW_LABEL,

      precondition: 'toggleLivePreview',
    });
    this.preview.actions.hide = instance.addAction({
      ...actionBasis,
      id: EXTENSION_MARKDOWN_PREVIEW_HIDE_ACTION_ID,
      label: EXTENSION_MARKDOWN_HIDE_PREVIEW_LABEL,

      precondition: '!toggleLivePreview',
    });
  }

  togglePreview(instance) {
    if (!this.preview?.el) {
      this.preview.el = setupDomElement({ injectToEl: instance.getDomNode().parentElement });
    }
    this.togglePreviewLayout(instance);
    this.togglePreviewPanel(instance);

    this.preview.actionShowPreviewCondition.set(!this.preview.actionShowPreviewCondition.get());

    if (!this.preview?.shown) {
      this.preview.modelChangeListener = instance.onDidChangeModelContent(
        debounce(this.fetchPreview.bind(this, instance), EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY),
      );
    } else {
      this.preview.modelChangeListener.dispose();
    }

    this.preview.shown = !this.preview?.shown;
    if (instance.toolbar) {
      instance.toolbar.updateItem(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID, {
        selected: this.preview.shown,
      });
    }
  }

  provides() {
    return {
      markdownPreview: this.preview,

      fetchPreview: (instance) => this.fetchPreview(instance),

      setupPreviewAction: (instance) => this.setupPreviewAction(instance),

      togglePreview: (instance) => this.togglePreview(instance),
    };
  }
}
