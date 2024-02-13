import { GlSorting } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { assertProps } from 'helpers/assert_props';
import ReleasesSort from '~/releases/components/releases_sort.vue';
import {
  RELEASED_AT,
  RELEASED_AT_ASC,
  RELEASED_AT_DESC,
  CREATED_AT,
  CREATED_ASC,
  CREATED_DESC,
  SORT_OPTIONS,
} from '~/releases/constants';

describe('releases_sort.vue', () => {
  let wrapper;

  const createComponent = (valueProp = RELEASED_AT_ASC) => {
    wrapper = shallowMountExtended(ReleasesSort, {
      propsData: {
        value: valueProp,
      },
    });
  };

  const findSorting = () => wrapper.findComponent(GlSorting);

  describe.each`
    valueProp           | text               | isAscending
    ${RELEASED_AT_ASC}  | ${'Released date'} | ${true}
    ${RELEASED_AT_DESC} | ${'Released date'} | ${false}
    ${CREATED_ASC}      | ${'Created date'}  | ${true}
    ${CREATED_DESC}     | ${'Created date'}  | ${false}
  `('component states', ({ valueProp, text, isAscending }) => {
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
  });

  const clickReleasedDateItem = () => findSorting().vm.$emit('sortByChange', RELEASED_AT);
  const clickCreatedDateItem = () => findSorting().vm.$emit('sortByChange', CREATED_AT);
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
        assertProps(ReleasesSort, { value: 'not a valid value' });
      }).toThrow('Invalid prop: custom validator check failed');
    });
  });

  describe('dropdown options', () => {
    it('sets sort options', () => {
      createComponent(RELEASED_AT_ASC);

      expect(findSorting().props()).toMatchObject({
        text: 'Released date',
        isAscending: true,
        sortBy: RELEASED_AT,
        sortOptions: SORT_OPTIONS,
      });
    });
  });
});
