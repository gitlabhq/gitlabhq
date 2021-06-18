import { Range } from 'monaco-editor';
import { waitForCSSLoaded } from '~/helpers/startup_css_helper';
import { ERROR_INSTANCE_REQUIRED_FOR_EXTENSION, EDITOR_TYPE_CODE } from '../constants';

const hashRegexp = new RegExp('#?L', 'g');

const createAnchor = (href) => {
  const fragment = new DocumentFragment();
  const el = document.createElement('a');
  el.classList.add('link-anchor');
  el.href = href;
  fragment.appendChild(el);
  el.addEventListener('contextmenu', (e) => {
    e.stopPropagation();
  });
  return fragment;
};

export class SourceEditorExtension {
  constructor({ instance, ...options } = {}) {
    if (instance) {
      Object.assign(instance, options);
      SourceEditorExtension.highlightLines(instance);
      if (instance.getEditorType && instance.getEditorType() === EDITOR_TYPE_CODE) {
        SourceEditorExtension.setupLineLinking(instance);
      }
      SourceEditorExtension.deferRerender(instance);
    } else if (Object.entries(options).length) {
      throw new Error(ERROR_INSTANCE_REQUIRED_FOR_EXTENSION);
    }
  }

  static deferRerender(instance) {
    waitForCSSLoaded(() => {
      instance.layout();
    });
  }

  static highlightLines(instance) {
    const { hash } = window.location;
    if (!hash) {
      return;
    }
    const [start, end] = hash.replace(hashRegexp, '').split('-');
    let startLine = start ? parseInt(start, 10) : null;
    let endLine = end ? parseInt(end, 10) : startLine;
    if (endLine < startLine) {
      [startLine, endLine] = [endLine, startLine];
    }
    if (startLine) {
      window.requestAnimationFrame(() => {
        instance.revealLineInCenter(startLine);
        Object.assign(instance, {
          lineDecorations: instance.deltaDecorations(
            [],
            [
              {
                range: new Range(startLine, 1, endLine, 1),
                options: { isWholeLine: true, className: 'active-line-text' },
              },
            ],
          ),
        });
      });
    }
  }

  static onMouseMoveHandler(e) {
    const target = e.target.element;
    if (target.classList.contains('line-numbers')) {
      const lineNum = e.target.position.lineNumber;
      const hrefAttr = `#L${lineNum}`;
      let el = target.querySelector('a');
      if (!el) {
        el = createAnchor(hrefAttr);
        target.appendChild(el);
      }
    }
  }

  static setupLineLinking(instance) {
    instance.onMouseMove(SourceEditorExtension.onMouseMoveHandler);
    instance.onMouseDown((e) => {
      const isCorrectAnchor = e.target.element.classList.contains('link-anchor');
      if (!isCorrectAnchor) {
        return;
      }
      if (instance.lineDecorations) {
        instance.deltaDecorations(instance.lineDecorations, []);
      }
    });
  }
}
