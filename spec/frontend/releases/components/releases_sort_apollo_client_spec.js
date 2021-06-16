import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReleasesSortApolloClient from '~/releases/components/releases_sort_apollo_client.vue';
import { RELEASED_AT_ASC, RELEASED_AT_DESC, CREATED_ASC, CREATED_DESC } from '~/releases/constants';

describe('releases_sort_apollo_client.vue', () => {
  let wrapper;

  const createComponent = (valueProp = RELEASED_AT_ASC) => {
    wrapper = shallowMountExtended(ReleasesSortApolloClient, {
      propsData: {
        value: valueProp,
      },
      stubs: {
        GlSortingItem,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findSorting = () => wrapper.findComponent(GlSorting);
  const findSortingItems = () => wrapper.findAllComponents(GlSortingItem);
  const findReleasedDateItem = () =>
    findSortingItems().wrappers.find((item) => item.text() === 'Released date');
  const findCreatedDateItem = () =>
    findSortingItems().wrappers.find((item) => item.text() === 'Created date');
  const getSortingItemsInfo = () =>
    findSortingItems().wrappers.map((item) => ({
      label: item.text(),
      active: item.attributes().active === 'true',
    }));

  describe.each`
    valueProp           | text               | isAscending | items
    ${RELEASED_AT_ASC}  | ${'Released date'} | ${true}     | ${[{ label: 'Released date', active: true }, { label: 'Created date', active: false }]}
    ${RELEASED_AT_DESC} | ${'Released date'} | ${false}    | ${[{ label: 'Released date', active: true }, { label: 'Created date', active: false }]}
    ${CREATED_ASC}      | ${'Created date'}  | ${true}     | ${[{ label: 'Released date', active: false }, { label: 'Created date', active: true }]}
    ${CREATED_DESC}     | ${'Created date'}  | ${false}    | ${[{ label: 'Released date', active: false }, { label: 'Created date', active: true }]}
  `('component states', ({ valueProp, text, isAscending, items }) => {
    beforeEach(() => {
      createComponent(valueProp);
    });

    it(`when the sort is ${valueProp}, provides the GlSorting with the props text="${text}" and isAscending=${isAscending}`, () => {
      expect(findSorting().props()).toEqual(
        expect.objectContaining({
          text,
          isAscending,
        }),
      );
    });

    it(`when the sort is ${valueProp}, renders the expected dropdown items`, () => {
      expect(getSortingItemsInfo()).toEqual(items);
    });
  });

  const clickReleasedDateItem = () => findReleasedDateItem().vm.$emit('click');
  const clickCreatedDateItem = () => findCreatedDateItem().vm.$emit('click');
  const clickSortDirectionButton = () => findSorting().vm.$emit('sortDirectionChange');

  const releasedAtDropdownItemDescription = 'released at dropdown item';
  const createdAtDropdownItemDescription = 'created at dropdown item';
  const sortDirectionButtonDescription = 'sort direction button';

  describe.each`
    initialValueProp    | itemClickFn                 | itemToClickDescription               | emittedEvent
    ${RELEASED_AT_ASC}  | ${clickReleasedDateItem}    | ${releasedAtDropdownItemDescription} | ${undefined}
    ${RELEASED_AT_ASC}  | ${clickCreatedDateItem}     | ${createdAtDropdownItemDescription}  | ${CREATED_ASC}
    ${RELEASED_AT_ASC}  | ${clickSortDirectionButton} | ${sortDirectionButtonDescription}    | ${RELEASED_AT_DESC}
    ${RELEASED_AT_DESC} | ${clickReleasedDateItem}    | ${releasedAtDropdownItemDescription} | ${undefined}
    ${RELEASED_AT_DESC} | ${clickCreatedDateItem}     | ${createdAtDropdownItemDescription}  | ${CREATED_DESC}
    ${RELEASED_AT_DESC} | ${clickSortDirectionButton} | ${sortDirectionButtonDescription}    | ${RELEASED_AT_ASC}
    ${CREATED_ASC}      | ${clickReleasedDateItem}    | ${releasedAtDropdownItemDescription} | ${RELEASED_AT_ASC}
    ${CREATED_ASC}      | ${clickCreatedDateItem}     | ${createdAtDropdownItemDescription}  | ${undefined}
    ${CREATED_ASC}      | ${clickSortDirectionButton} | ${sortDirectionButtonDescription}    | ${CREATED_DESC}
    ${CREATED_DESC}     | ${clickReleasedDateItem}    | ${releasedAtDropdownItemDescription} | ${RELEASED_AT_DESC}
    ${CREATED_DESC}     | ${clickCreatedDateItem}     | ${createdAtDropdownItemDescription}  | ${undefined}
    ${CREATED_DESC}     | ${clickSortDirectionButton} | ${sortDirectionButtonDescription}    | ${CREATED_ASC}
  `('input event', ({ initialValueProp, itemClickFn, itemToClickDescription, emittedEvent }) => {
    beforeEach(() => {
      createComponent(initialValueProp);
      itemClickFn();
    });

    it(`emits ${
      emittedEvent || 'nothing'
    } when value prop is ${initialValueProp} and the ${itemToClickDescription} is clicked`, () => {
      expect(wrapper.emitted().input?.[0]?.[0]).toEqual(emittedEvent);
    });
  });

  describe('prop validation', () => {
    it('validates that the `value` prop is one of the expected sort strings', () => {
      expect(() => {
        createComponent('not a valid value');
      }).toThrow('Invalid prop: custom validator check failed');
    });
  });
});
