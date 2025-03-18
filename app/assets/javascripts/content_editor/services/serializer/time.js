import { openTag, closeTag } from '../serialization_helpers';

const time = (state, node) => {
  state.write(openTag('time', node.attrs));
  state.renderInline(node);
  state.write(closeTag('time'));
};
export default time;
