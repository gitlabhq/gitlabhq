export const serializeFormEntries = entries =>
  entries.reduce((acc, { name, value }) => Object.assign(acc, { [name]: value }), {});

export const serializeForm = form => {
  const fdata = new FormData(form);
  const entries = Array.from(fdata.keys()).map(key => {
    const val = fdata.getAll(key);
    return { name: key, value: val.length === 1 ? val[0] : val };
  });

  return serializeFormEntries(entries);
};
