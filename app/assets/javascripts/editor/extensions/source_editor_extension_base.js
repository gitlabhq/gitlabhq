import { Range } from 'monaco-editor';
import { __ } from '~/locale';
import {
  EDITOR_TYPE_CODE,
  EXTENSION_BASE_LINE_LINK_ANCHOR_CLASS,
  EXTENSION_BASE_LINE_NUMBERS_CLASS,
  EDITOR_TOOLBAR_BUTTON_GROUPS,
  EXTENSION_SOFTWRAP_ID,
} from '../constants';

const hashRegexp = /#?L/g;

const createAnchor = (href) => {
  const fragment = new DocumentFragment();
  const el = document.createElement('a');
  el.classList.add(EXTENSION_BASE_LINE_LINK_ANCHOR_CLASS);
  el.href = href;
  fragment.appendChild(el);
  el.addEventListener('contextmenu', (e) => {
    e.stopPropagation();
  });
  return fragment;
};

export class SourceEditorExtension {
  static get extensionName() {
    return 'BaseExtension';
  }

  onSetup(instance) {
    this.toolbarButtons = [];
    if (instance.toolbar) {
      this.setupToolbar(instance);
    }
  }

  // eslint-disable-next-line class-methods-use-this
  onUse(instance) {
    SourceEditorExtension.highlightLines(instance);
    if (instance.getEditorType && instance.getEditorType() === EDITOR_TYPE_CODE) {
      SourceEditorExtension.setupLineLinking(instance);
    }
  }

  onBeforeUnuse(instance) {
    const ids = this.toolbarButtons.map((item) => item.id);
    if (instance.toolbar) {
      instance.toolbar.removeItems(ids);
    }
  }

  setupToolbar(instance) {
    this.toolbarButtons = [
      {
        id: EXTENSION_SOFTWRAP_ID,
        label: __('Soft wrap'),
        icon: 'soft-wrap',
        selected: instance.getOption(116) === 'on',
        group: EDITOR_TOOLBAR_BUTTON_GROUPS.settings,
        category: 'primary',
        selectedLabel: __('No wrap'),
        selectedIcon: 'soft-unwrap',
        class: 'soft-wrap-toggle',
        onClick: () => instance.toggleSoftwrap(),
      },
    ];
    instance.toolbar.addItems(this.toolbarButtons);
  }

  static onMouseMoveHandler(e) {
    const target = e.target.element;
    if (target.classList.contains(EXTENSION_BASE_LINE_NUMBERS_CLASS)) {
      const lineNum = e.target.position.lineNumber;
      const hrefAttr = `#L${lineNum}`;
      let lineLink = target.querySelector('a');
      if (!lineLink) {
        lineLink = createAnchor(hrefAttr);
        target.appendChild(lineLink);
      }
    }
  }

  static setupLineLinking(instance) {
    instance.onMouseMove(SourceEditorExtension.onMouseMoveHandler);
    instance.onMouseDown((e) => {
      const isCorrectAnchor = e.target.element.classList.contains(
        EXTENSION_BASE_LINE_LINK_ANCHOR_CLASS,
      );
      if (!isCorrectAnchor) {
        return;
      }
      if (instance.lineDecorations) {
        instance.deltaDecorations(instance.lineDecorations, []);
      }
    });
  }

  static highlightLines(instance, bounds = null) {
    const [start, end] =
      bounds && Array.isArray(bounds)
        ? bounds
        : window.location.hash.replace(hashRegexp, '').split('-');
    let startLine = start ? parseInt(start, 10) : null;
    let endLine = end ? parseInt(end, 10) : startLine;
    if (endLine < startLine) {
      [startLine, endLine] = [endLine, startLine];
    }
    if (startLine) {
      window.requestAnimationFrame(() => {
        instance.revealLineInCenter(startLine);
        Object.assign(instance, {
          lineDecorations: instance.deltaDecorations(instance.lineDecorations || [], [
            {
              range: new Range(startLine, 1, endLine, 1),
              options: { isWholeLine: true, className: 'active-line-text' },
            },
          ]),
        });
      });
    }
  }

  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      /**
       * Removes existing line decorations and updates the reference on the instance
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
       */
      removeHighlights: (instance) => {
        Object.assign(instance, {
          lineDecorations: instance.deltaDecorations(instance.lineDecorations || [], []),
        });
      },

      /**
       * Returns a function that can only be invoked once between
       * each browser screen repaint.
       * @param {Array} bounds - The [start, end] array with start
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
       * and end coordinates for highlighting
       */
      highlightLines(instance, bounds = null) {
        SourceEditorExtension.highlightLines(instance, bounds);
      },

      toggleSoftwrap(instance) {
        const isSoftWrapped = instance.getOption(116) === 'on';
        instance.updateOptions({ wordWrap: isSoftWrapped ? 'off' : 'on' });
        if (instance.toolbar) {
          instance.toolbar.updateItem(EXTENSION_SOFTWRAP_ID, {
            selected: !isSoftWrapped,
          });
          document.querySelector('.soft-wrap-toggle')?.blur();
        }
      },
    };
  }
}
