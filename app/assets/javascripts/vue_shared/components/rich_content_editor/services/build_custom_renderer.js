import renderHtml from './renderers/render_html';
import renderKramdownList from './renderers/render_kramdown_list';
import renderKramdownText from './renderers/render_kramdown_text';
import renderIdentifierParagraph from './renderers/render_identifier_paragraph';
import renderEmbeddedRubyText from './renderers/render_embedded_ruby_text';

const htmlRenderers = [renderHtml];
const listRenderers = [renderKramdownList];
const paragraphRenderers = [renderIdentifierParagraph];
const textRenderers = [renderKramdownText, renderEmbeddedRubyText];

const executeRenderer = (renderers, node, context) => {
  const availableRenderer = renderers.find(renderer => renderer.canRender(node, context));

  return availableRenderer ? availableRenderer.render(node, context) : context.origin();
};

const buildCustomRendererFunctions = (customRenderers, defaults) => {
  const customTypes = Object.keys(customRenderers).filter(type => !defaults[type]);
  const customEntries = customTypes.map(type => {
    const fn = (node, context) => executeRenderer(customRenderers[type], node, context);
    return [type, fn];
  });

  return Object.fromEntries(customEntries);
};

const buildCustomHTMLRenderer = (
  customRenderers = { htmlBlock: [], list: [], paragraph: [], text: [] },
) => {
  const defaults = {
    htmlBlock(node, context) {
      const allHtmlRenderers = [...customRenderers.list, ...htmlRenderers];

      return executeRenderer(allHtmlRenderers, node, context);
    },
    list(node, context) {
      const allListRenderers = [...customRenderers.list, ...listRenderers];

      return executeRenderer(allListRenderers, node, context);
    },
    paragraph(node, context) {
      const allParagraphRenderers = [...customRenderers.list, ...paragraphRenderers];

      return executeRenderer(allParagraphRenderers, node, context);
    },
    text(node, context) {
      const allTextRenderers = [...customRenderers.text, ...textRenderers];

      return executeRenderer(allTextRenderers, node, context);
    },
  };

  return {
    ...buildCustomRendererFunctions(customRenderers, defaults),
    ...defaults,
  };
};

export default buildCustomHTMLRenderer;
