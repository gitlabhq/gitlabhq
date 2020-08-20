import { union, mapValues } from 'lodash';
import renderBlockHtml from './renderers/render_html_block';
import renderKramdownList from './renderers/render_kramdown_list';
import renderKramdownText from './renderers/render_kramdown_text';
import renderIdentifierInstanceText from './renderers/render_identifier_instance_text';
import renderIdentifierParagraph from './renderers/render_identifier_paragraph';
import renderFontAwesomeHtmlInline from './renderers/render_font_awesome_html_inline';
import renderSoftbreak from './renderers/render_softbreak';

const htmlInlineRenderers = [renderFontAwesomeHtmlInline];
const htmlBlockRenderers = [renderBlockHtml];
const listRenderers = [renderKramdownList];
const paragraphRenderers = [renderIdentifierParagraph];
const textRenderers = [renderKramdownText, renderIdentifierInstanceText];
const softbreakRenderers = [renderSoftbreak];

const executeRenderer = (renderers, node, context) => {
  const availableRenderer = renderers.find(renderer => renderer.canRender(node, context));

  return availableRenderer ? availableRenderer.render(node, context) : context.origin();
};

const buildCustomHTMLRenderer = customRenderers => {
  const renderersByType = {
    ...customRenderers,
    htmlBlock: union(htmlBlockRenderers, customRenderers?.htmlBlock),
    htmlInline: union(htmlInlineRenderers, customRenderers?.htmlInline),
    list: union(listRenderers, customRenderers?.list),
    paragraph: union(paragraphRenderers, customRenderers?.paragraph),
    text: union(textRenderers, customRenderers?.text),
    softbreak: union(softbreakRenderers, customRenderers?.softbreak),
  };

  return mapValues(renderersByType, renderers => {
    return (node, context) => executeRenderer(renderers, node, context);
  });
};

export default buildCustomHTMLRenderer;
