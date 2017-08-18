const DateFix = {
  dashedFix(val) {
    const [y, m, d] = val.split('-');
    return new Date(y, m - 1, d);
  },
};

export default DateFix;
