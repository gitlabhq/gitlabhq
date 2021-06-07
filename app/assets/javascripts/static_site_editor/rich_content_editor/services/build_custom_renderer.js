import { union, mapValues } from 'lodash';
import renderAttributeDefinition from './renderers/render_attribute_definition';
import renderFontAwesomeHtmlInline from './renderers/render_font_awesome_html_inline';
import renderHeading from './renderers/render_heading';
import renderBlockHtml from './renderers/render_html_block';
import renderIdentifierInstanceText from './renderers/render_identifier_instance_text';
import renderIdentifierParagraph from './renderers/render_identifier_paragraph';
import renderListItem from './renderers/render_list_item';
import renderSoftbreak from './renderers/render_softbreak';

const htmlInlineRenderers = [renderFontAwesomeHtmlInline];
const htmlBlockRenderers = [renderBlockHtml];
const headingRenderers = [renderHeading];
const paragraphRenderers = [renderIdentifierParagraph, renderBlockHtml];
const textRenderers = [renderIdentifierInstanceText, renderAttributeDefinition];
const listItemRenderers = [renderListItem];
const softbreakRenderers = [renderSoftbreak];

const executeRenderer = (renderers, node, context) => {
  const availableRenderer = renderers.find((renderer) => renderer.canRender(node, context));

  return availableRenderer ? availableRenderer.render(node, context) : context.origin();
};

const buildCustomHTMLRenderer = (customRenderers) => {
  const renderersByType = {
    ...customRenderers,
    htmlBlock: union(htmlBlockRenderers, customRenderers?.htmlBlock),
    htmlInline: union(htmlInlineRenderers, customRenderers?.htmlInline),
    heading: union(headingRenderers, customRenderers?.heading),
    item: union(listItemRenderers, customRenderers?.listItem),
    paragraph: union(paragraphRenderers, customRenderers?.paragraph),
    text: union(textRenderers, customRenderers?.text),
    softbreak: union(softbreakRenderers, customRenderers?.softbreak),
  };

  return mapValues(renderersByType, (renderers) => {
    return (node, context) => executeRenderer(renderers, node, context);
  });
};

export default buildCustomHTMLRenderer;
