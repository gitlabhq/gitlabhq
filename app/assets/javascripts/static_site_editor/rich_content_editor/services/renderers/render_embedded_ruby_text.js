import { renderUneditableLeaf as render } from './render_utils';

const embeddedRubyRegex = /(^<%.+%>$)/;

const canRender = ({ literal }) => {
  return embeddedRubyRegex.test(literal);
};

export default { canRender, render };
