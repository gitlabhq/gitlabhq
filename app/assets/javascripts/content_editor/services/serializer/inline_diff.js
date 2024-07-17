const inlineDiff = {
  mixable: true,
  open(_, mark) {
    return mark.attrs.type === 'addition' ? '{+' : '{-';
  },
  close(_, mark) {
    return mark.attrs.type === 'addition' ? '+}' : '-}';
  },
};

export default inlineDiff;
