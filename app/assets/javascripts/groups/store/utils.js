export const getGroupItemMicrodata = ({ type }) => {
  const defaultMicrodata = {
    itemscope: true,
    itemtype: 'https://schema.org/Thing',
    itemprop: 'owns',
    imageItemprop: 'image',
    nameItemprop: 'name',
    descriptionItemprop: 'description',
  };

  switch (type) {
    case 'group':
      return {
        ...defaultMicrodata,
        itemtype: 'https://schema.org/Organization',
        itemprop: 'subOrganization',
        imageItemprop: 'logo',
      };
    case 'project':
      return {
        ...defaultMicrodata,
        itemtype: 'https://schema.org/SoftwareSourceCode',
      };
    default:
      return defaultMicrodata;
  }
};
