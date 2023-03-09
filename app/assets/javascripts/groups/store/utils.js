import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';

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
    case WORKSPACE_GROUP:
      return {
        ...defaultMicrodata,
        itemtype: 'https://schema.org/Organization',
        itemprop: 'subOrganization',
        imageItemprop: 'logo',
      };
    case WORKSPACE_PROJECT:
      return {
        ...defaultMicrodata,
        itemtype: 'https://schema.org/SoftwareSourceCode',
      };
    default:
      return defaultMicrodata;
  }
};
