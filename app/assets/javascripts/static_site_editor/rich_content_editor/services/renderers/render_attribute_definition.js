import { isAttributeDefinition } from './render_utils';

const canRender = ({ literal }) => isAttributeDefinition(literal);

const render = () => ({ type: 'html', content: '<!-- sse-attribute-definition -->' });

export default { canRender, render };
