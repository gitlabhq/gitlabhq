export const findSelectedOptionValueByLabel = (options, label) => {
  const option = options.find((opt) => opt.label === label);
  return option?.value || options[0]?.value;
};
