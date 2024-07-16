import { getGroupItemMicrodata } from '~/groups/store/utils';

describe('~/groups/store/utils', () => {
  describe('getGroupItemMetadata', () => {
    it('has default type', () => {
      expect(getGroupItemMicrodata({ type: 'silly' })).toMatchInlineSnapshot(`
{
  "descriptionItemprop": "description",
  "imageItemprop": "image",
  "itemprop": "owns",
  "itemscope": true,
  "itemtype": "https://schema.org/Thing",
  "nameItemprop": "name",
}
`);
    });

    it('has group props', () => {
      expect(getGroupItemMicrodata({ type: 'group' })).toMatchInlineSnapshot(`
{
  "descriptionItemprop": "description",
  "imageItemprop": "logo",
  "itemprop": "subOrganization",
  "itemscope": true,
  "itemtype": "https://schema.org/Organization",
  "nameItemprop": "name",
}
`);
    });

    it('has project props', () => {
      expect(getGroupItemMicrodata({ type: 'project' })).toMatchInlineSnapshot(`
{
  "descriptionItemprop": "description",
  "imageItemprop": "image",
  "itemprop": "owns",
  "itemscope": true,
  "itemtype": "https://schema.org/SoftwareSourceCode",
  "nameItemprop": "name",
}
`);
    });
  });
});
