export const serializeFormEntries = entries =>
  entries.reduce((acc, { name, value }) => Object.assign(acc, { [name]: value }), {});

export const serializeForm = form => {
  const fdata = new FormData(form);
  const entries = Array.from(fdata.keys()).map(key => {
    let val = fdata.getAll(key);
    // Microsoft Edge has a bug in FormData.getAll() that returns an undefined
    // value for each form element that does not match the given key:
    // https://github.com/jimmywarting/FormData/issues/80
    val = val.filter(n => n);
    return { name: key, value: val.length === 1 ? val[0] : val };
  });

  return serializeFormEntries(entries);
};
