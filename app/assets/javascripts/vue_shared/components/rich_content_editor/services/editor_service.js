import { defaults } from 'lodash';
import Vue from 'vue';
import { TOOLBAR_ITEM_CONFIGS, VIDEO_ATTRIBUTES } from '../constants';
import ToolbarItem from '../toolbar_item.vue';
import buildCustomHTMLRenderer from './build_custom_renderer';
import buildHtmlToMarkdownRenderer from './build_html_to_markdown_renderer';
import sanitizeHTML from './sanitize_html';

const buildWrapper = (propsData) => {
  const instance = new Vue({
    render(createElement) {
      return createElement(ToolbarItem, propsData);
    },
  });

  instance.$mount();
  return instance.$el;
};

const buildVideoIframe = (src) => {
  const wrapper = document.createElement('figure');
  const iframe = document.createElement('iframe');
  const videoAttributes = { ...VIDEO_ATTRIBUTES, src };
  const wrapperClasses = ['gl-relative', 'gl-h-0', 'video_container'];
  const iframeClasses = ['gl-absolute', 'gl-top-0', 'gl-left-0', 'gl-w-full', 'gl-h-full'];

  wrapper.setAttribute('contenteditable', 'false');
  wrapper.classList.add(...wrapperClasses);
  iframe.classList.add(...iframeClasses);
  Object.assign(iframe, videoAttributes);

  wrapper.appendChild(iframe);

  return wrapper;
};

const buildImg = (alt, originalSrc, file) => {
  const img = document.createElement('img');
  const src = file ? URL.createObjectURL(file) : originalSrc;
  const attributes = { alt, src };

  if (file) {
    img.dataset.originalSrc = originalSrc;
  }

  Object.assign(img, attributes);

  return img;
};

export const generateToolbarItem = (config) => {
  const { icon, classes, event, command, tooltip, isDivider } = config;

  if (isDivider) {
    return 'divider';
  }

  return {
    type: 'button',
    options: {
      el: buildWrapper({ props: { icon, tooltip }, class: classes }),
      event,
      command,
    },
  };
};

export const addCustomEventListener = (editorApi, event, handler) => {
  editorApi.eventManager.addEventType(event);
  editorApi.eventManager.listen(event, handler);
};

export const removeCustomEventListener = (editorApi, event, handler) =>
  editorApi.eventManager.removeEventHandler(event, handler);

export const addImage = ({ editor }, { altText, imageUrl }, file) => {
  if (editor.isWysiwygMode()) {
    const img = buildImg(altText, imageUrl, file);
    editor.getSquire().insertElement(img);
  } else {
    editor.insertText(`![${altText}](${imageUrl})`);
  }
};

export const insertVideo = ({ editor }, url) => {
  const videoIframe = buildVideoIframe(url);

  if (editor.isWysiwygMode()) {
    editor.getSquire().insertElement(videoIframe);
  } else {
    editor.insertText(videoIframe.outerHTML);
  }
};

export const getMarkdown = (editorInstance) => editorInstance.invoke('getMarkdown');

/**
 * This function allow us to extend Toast UI HTML to Markdown renderer. It is
 * a temporary measure because Toast UI does not provide an API
 * to achieve this goal.
 */
export const registerHTMLToMarkdownRenderer = (editorApi) => {
  const { renderer } = editorApi.toMarkOptions;

  Object.assign(editorApi.toMarkOptions, {
    renderer: renderer.constructor.factory(renderer, buildHtmlToMarkdownRenderer(renderer)),
  });
};

export const getEditorOptions = (externalOptions) => {
  return defaults({
    customHTMLRenderer: buildCustomHTMLRenderer(externalOptions?.customRenderers),
    toolbarItems: TOOLBAR_ITEM_CONFIGS.map((toolbarItem) => generateToolbarItem(toolbarItem)),
    customHTMLSanitizer: (html) => sanitizeHTML(html),
  });
};
