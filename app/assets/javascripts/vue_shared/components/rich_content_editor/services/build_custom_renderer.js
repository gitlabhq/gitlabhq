import renderKramdownList from './renderers/render_kramdown_list';
import renderKramdownText from './renderers/render_kramdown_text';
import renderIdentifierText from './renderers/render_identifier_text';
import renderEmbeddedRubyText from './renderers/render_embedded_ruby_text';

const listRenderers = [renderKramdownList];
const textRenderers = [renderKramdownText, renderIdentifierText, renderEmbeddedRubyText];

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

const buildCustomHTMLRenderer = (customRenderers = { list: [], text: [] }) => {
  const defaults = {
    list(node, context) {
      const allListRenderers = [...customRenderers.list, ...listRenderers];

      return executeRenderer(allListRenderers, node, context);
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
