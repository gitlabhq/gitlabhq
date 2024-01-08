import { GlKeysetPagination } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourcesList from '~/ci/catalog/components/list/ci_resources_list.vue';
import CiResourcesListItem from '~/ci/catalog/components/list/ci_resources_list_item.vue';
import { catalogResponseBody, catalogSinglePageResponse } from '../../mock';

describe('CiResourcesList', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    const { nodes, pageInfo } = catalogResponseBody.data.ciCatalogResources;

    const defaultProps = {
      currentPage: 1,
      resources: nodes,
      pageInfo,
      totalCount: 20,
    };

    wrapper = shallowMountExtended(CiResourcesList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlKeysetPagination,
      },
    });
  };

  const findPageCount = () => wrapper.findByTestId('pageCount');
  const findResourcesListItems = () => wrapper.findAllComponents(CiResourcesListItem);
  const findPrevBtn = () => wrapper.findByTestId('prevButton');
  const findNextBtn = () => wrapper.findByTestId('nextButton');

  describe('contains only one page', () => {
    const { nodes, pageInfo } = catalogSinglePageResponse.data.ciCatalogResources;

    beforeEach(async () => {
      await createComponent({
        props: { currentPage: 1, resources: nodes, pageInfo, totalCount: nodes.length },
      });
    });

    it('shows the right number of items', () => {
      expect(findResourcesListItems()).toHaveLength(nodes.length);
    });

    it('hides the keyset control for previous page', () => {
      expect(findPrevBtn().exists()).toBe(false);
    });

    it('hides the keyset control for next page', () => {
      expect(findNextBtn().exists()).toBe(false);
    });

    it('shows the correct count of current page', () => {
      expect(findPageCount().text()).toContain('1 of 1');
    });
  });

  describe.each`
    hasPreviousPage | hasNextPage | pageText    | currentPage
    ${false}        | ${true}     | ${'1 of 3'} | ${1}
    ${true}         | ${true}     | ${'2 of 3'} | ${2}
    ${true}         | ${false}    | ${'3 of 3'} | ${3}
  `('when on page $pageText', ({ currentPage, pageText, hasPreviousPage, hasNextPage }) => {
    const { nodes, pageInfo } = catalogResponseBody.data.ciCatalogResources;
    const count = 50; // We want 3 pages of data to test. There are 20 items per page.

    const previousPageState = hasPreviousPage ? 'enabled' : 'disabled';
    const nextPageState = hasNextPage ? 'enabled' : 'disabled';

    beforeEach(async () => {
      await createComponent({
        props: {
          currentPage,
          resources: nodes,
          pageInfo: { ...pageInfo, hasPreviousPage, hasNextPage },
          totalCount: count,
        },
      });
    });

    it('shows the right number of items', () => {
      expect(findResourcesListItems()).toHaveLength(20);
    });

    it(`shows the keyset control for previous page as ${previousPageState}`, () => {
      const disableAttr = findPrevBtn().attributes('disabled');

      if (previousPageState === 'disabled') {
        expect(disableAttr).toBeDefined();
      } else {
        expect(disableAttr).toBeUndefined();
      }
    });

    it(`shows the keyset control for next page as ${nextPageState}`, () => {
      const disableAttr = findNextBtn().attributes('disabled');

      if (nextPageState === 'disabled') {
        expect(disableAttr).toBeDefined();
      } else {
        expect(disableAttr).toBeUndefined();
      }
    });

    it('shows the correct count of current page', () => {
      expect(findPageCount().text()).toContain(pageText);
    });
  });

  describe('when there is an error getting the page count', () => {
    beforeEach(() => {
      createComponent({ props: { totalCount: 0 } });
    });

    it('hides the page count', () => {
      expect(findPageCount().exists()).toBe(false);
    });
  });

  describe('emitted events', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      btnText       | elFinder       | eventName
      ${'previous'} | ${findPrevBtn} | ${'onPrevPage'}
      ${'next'}     | ${findNextBtn} | ${'onNextPage'}
    `('emits $eventName when clicking on the $btnText button', async ({ elFinder, eventName }) => {
      await elFinder().vm.$emit('click');

      expect(wrapper.emitted(eventName)).toHaveLength(1);
    });
  });
});
