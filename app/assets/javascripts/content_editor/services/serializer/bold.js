function renderBold() {
  return '**';
}

const bold = {
  open: renderBold,
  close: renderBold,
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default bold;
