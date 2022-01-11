import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import { spriteIcon } from '~/lib/utils/common_utils';
import { setAttributes } from '~/lib/utils/dom_utils';

class CopyCodeButton extends HTMLElement {
  connectedCallback() {
    this.for = uniqueId('code-');

    this.parentNode.querySelector('pre').setAttribute('id', this.for);

    this.appendChild(this.createButton());
  }

  createButton() {
    const button = document.createElement('button');

    setAttributes(button, {
      type: 'button',
      class: 'btn btn-default btn-md gl-button btn-icon has-tooltip',
      'data-title': __('Copy to clipboard'),
      'data-clipboard-target': `pre#${this.for}`,
    });

    button.innerHTML = spriteIcon('copy-to-clipboard');

    return button;
  }
}

function addCodeButton() {
  [...document.querySelectorAll('pre.code.js-syntax-highlight:not(.content-editor-code-block)')]
    .filter((el) => el.attr('lang') !== 'mermaid')
    .filter((el) => !el.closest('.js-markdown-code'))
    .forEach((el) => {
      const copyCodeEl = document.createElement('copy-code');
      copyCodeEl.setAttribute('for', uniqueId('code-'));

      const wrapper = document.createElement('div');
      wrapper.className = 'gl-relative markdown-code-block js-markdown-code';
      wrapper.appendChild(el.cloneNode(true));
      wrapper.appendChild(copyCodeEl);

      el.parentNode.insertBefore(wrapper, el);

      el.remove();
    });
}

export const initCopyCodeButton = (selector = '#content-body') => {
  if (!customElements.get('copy-code')) {
    customElements.define('copy-code', CopyCodeButton);
  }

  const el = document.querySelector(selector);

  if (!el) return () => {};

  const observer = new MutationObserver(() => addCodeButton());

  observer.observe(document.querySelector(selector), {
    childList: true,
    subtree: true,
  });

  return () => observer.disconnect();
};
