const DateFix = {
  dashedFix(val) {
    const [y, m, d] = val.split('-');
    console.log(y,m,d)
    return new Date(y, m - 1, d);
  }
}

export default DateFix;