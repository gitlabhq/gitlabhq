import { NAMESPACE_GROUP, NAMESPACE_PROJECT } from '~/issues/constants';

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
    case NAMESPACE_GROUP:
      return {
        ...defaultMicrodata,
        itemtype: 'https://schema.org/Organization',
        itemprop: 'subOrganization',
        imageItemprop: 'logo',
      };
    case NAMESPACE_PROJECT:
      return {
        ...defaultMicrodata,
        itemtype: 'https://schema.org/SoftwareSourceCode',
      };
    default:
      return defaultMicrodata;
  }
};
