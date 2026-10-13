import { recordDelimiter } from '../emphasis_delimiters';

const renderBold = (state, mark) => recordDelimiter(state, mark, '**');

const bold = {
  open: renderBold,
  close: renderBold,
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default bold;
