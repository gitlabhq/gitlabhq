import { GlKeysetPagination } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Pagination from '~/ml/experiment_tracking/components/pagination.vue';

describe('~/vue_shared/incubation/components/pagination.vue', () => {
  let wrapper;

  const pageInfo = {
    startCursor: 'eyJpZCI6IjE2In0',
    endCursor: 'eyJpZCI6IjIifQ',
    hasNextPage: true,
    hasPreviousPage: true,
  };

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  const createWrapper = (pageInfoProp) => {
    wrapper = mountExtended(Pagination, {
      propsData: pageInfoProp,
    });
  };

  describe('when neither next nor previous page exists', () => {
    beforeEach(() => {
      const emptyPageInfo = { ...pageInfo, hasPreviousPage: false, hasNextPage: false };

      createWrapper(emptyPageInfo);
    });

    it('should not render pagination component', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });

  describe('when Pagination is rendered for environment details page', () => {
    beforeEach(() => {
      createWrapper(pageInfo);
    });

    it('should pass correct props to keyset pagination', () => {
      expect(findPagination().exists()).toBe(true);
      expect(findPagination().props()).toEqual(expect.objectContaining(pageInfo));
    });

    describe.each([
      {
        testPageInfo: pageInfo,
        expectedAfter: `cursor=${pageInfo.endCursor}`,
        expectedBefore: `cursor=${pageInfo.startCursor}`,
      },
      {
        testPageInfo: { ...pageInfo, hasNextPage: true, hasPreviousPage: false },
        expectedAfter: `cursor=${pageInfo.endCursor}`,
        expectedBefore: '',
      },
      {
        testPageInfo: { ...pageInfo, hasNextPage: false, hasPreviousPage: true },
        expectedAfter: '',
        expectedBefore: `cursor=${pageInfo.startCursor}`,
      },
    ])(
      'button links generation for $testPageInfo',
      ({ testPageInfo, expectedAfter, expectedBefore }) => {
        beforeEach(() => {
          createWrapper(testPageInfo);
        });

        it(`should have button links defined as ${expectedAfter || 'empty'} and
        ${expectedBefore || 'empty'}`, () => {
          expect(findPagination().props().prevButtonLink).toContain(expectedBefore);
          expect(findPagination().props().nextButtonLink).toContain(expectedAfter);
        });
      },
    );
  });
});
