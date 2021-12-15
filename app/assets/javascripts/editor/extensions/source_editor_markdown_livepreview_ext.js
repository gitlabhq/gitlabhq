import { debounce } from 'lodash';
import { BLOB_PREVIEW_ERROR } from '~/blob_edit/constants';
import createFlash from '~/flash';
import { sanitize } from '~/lib/dompurify';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import syntaxHighlight from '~/syntax_highlight';
import {
  EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY,
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
      action: undefined,
      shown: false,
      modelChangeListener: undefined,
      path: setupOptions.previewMarkdownPath,
    };
    this.setupPreviewAction(instance);

    instance.getModel().onDidChangeLanguage(({ newLanguage, oldLanguage } = {}) => {
      if (newLanguage === 'markdown' && oldLanguage !== newLanguage) {
        instance.setupPreviewAction();
      } else {
        instance.cleanup();
      }
    });

    instance.onDidChangeModel(() => {
      const model = instance.getModel();
      if (model) {
        const { language } = model.getLanguageIdentifier();
        instance.cleanup();
        if (language === 'markdown') {
          instance.setupPreviewAction();
        }
      }
    });
  }

  togglePreviewLayout(instance) {
    const { width, height } = instance.getLayoutInfo();
    const newWidth = this.preview.shown
      ? width / EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH
      : width * EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH;
    instance.layout({ width: newWidth, height });
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
        syntaxHighlight(previewEl.querySelectorAll('.js-syntax-highlight'));
        previewEl.style.display = 'block';
      })
      .catch(() => createFlash(BLOB_PREVIEW_ERROR));
  }

  setupPreviewAction(instance) {
    if (instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)) return;

    this.preview.action = instance.addAction({
      id: EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
      label: __('Preview Markdown'),
      keybindings: [
        // eslint-disable-next-line no-bitwise,no-undef
        monaco.KeyMod.chord(monaco.KeyMod.CtrlCmd | monaco.KeyMod.Shift | monaco.KeyCode.KEY_P),
      ],
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 1.5,

      // Method that will be executed when the action is triggered.
      // @param ed The editor instance is passed in as a convenience
      run(inst) {
        inst.togglePreview();
      },
    });
  }

  provides() {
    return {
      markdownPreview: this.preview,

      cleanup: (instance) => {
        if (this.preview.modelChangeListener) {
          this.preview.modelChangeListener.dispose();
        }
        this.preview.action.dispose();
        if (this.preview.shown) {
          this.togglePreviewPanel(instance);
          this.togglePreviewLayout(instance);
        }
        this.preview.shown = false;
      },

      fetchPreview: (instance) => this.fetchPreview(instance),

      setupPreviewAction: (instance) => this.setupPreviewAction(instance),

      togglePreview: (instance) => {
        if (!this.preview?.el) {
          this.preview.el = setupDomElement({ injectToEl: instance.getDomNode().parentElement });
        }
        this.togglePreviewLayout(instance);
        this.togglePreviewPanel(instance);

        if (!this.preview?.shown) {
          this.preview.modelChangeListener = instance.onDidChangeModelContent(
            debounce(
              this.fetchPreview.bind(this, instance),
              EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY,
            ),
          );
        } else {
          this.preview.modelChangeListener.dispose();
        }

        this.preview.shown = !this.preview?.shown;
      },
    };
  }
}
