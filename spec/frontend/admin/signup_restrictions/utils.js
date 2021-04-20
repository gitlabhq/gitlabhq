export const setDataAttributes = (data, element) => {
  Object.keys(data).forEach((key) => {
    const value = data[key];

    // attribute should be:
    // - valueless if value is 'true'
    // - absent if value is 'false'
    switch (value) {
      case false:
        break;
      case true:
        element.dataset[`${key}`] = '';
        break;
      default:
        element.dataset[`${key}`] = value;
        break;
    }
  });
};
