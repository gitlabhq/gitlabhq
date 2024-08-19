import { GlKeysetPagination } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Pagination from '~/environments/environment_details/pagination.vue';

describe('~/environments/environment_details/pagniation.vue', () => {
  const mockRouter = {
    push: jest.fn(),
  };

  const pageInfo = {
    startCursor: 'eyJpZCI6IjE2In0',
    endCursor: 'eyJpZCI6IjIifQ',
    hasNextPage: true,
    hasPreviousPage: true,
  };
  let wrapper;

  const createWrapper = (pageInfoProp) => {
    return mountExtended(Pagination, {
      propsData: {
        pageInfo: pageInfoProp,
      },
      mocks: {
        $router: mockRouter,
      },
    });
  };

  describe('when neither next nor previous page exists', () => {
    beforeEach(() => {
      const emptyPageInfo = { ...pageInfo, hasPreviousPage: false, hasNextPage: false };
      wrapper = createWrapper(emptyPageInfo);
    });

    it('should not render pagination component', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });

  describe('when Pagination is rendered for environment details page', () => {
    beforeEach(() => {
      wrapper = createWrapper(pageInfo);
    });

    it('should pass correct props to keyset pagination', () => {
      const glPagination = wrapper.findComponent(GlKeysetPagination);
      expect(glPagination.exists()).toBe(true);
      expect(glPagination.props()).toEqual(expect.objectContaining(pageInfo));
    });

    describe.each([
      {
        testPageInfo: pageInfo,
        expectedAfter: `after=${pageInfo.endCursor}`,
        expectedBefore: `before=${pageInfo.startCursor}`,
      },
      {
        testPageInfo: { ...pageInfo, hasNextPage: true, hasPreviousPage: false },
        expectedAfter: `after=${pageInfo.endCursor}`,
        expectedBefore: '',
      },
      {
        testPageInfo: { ...pageInfo, hasNextPage: false, hasPreviousPage: true },
        expectedAfter: '',
        expectedBefore: `before=${pageInfo.startCursor}`,
      },
    ])(
      'button links generation for $testPageInfo',
      ({ testPageInfo, expectedAfter, expectedBefore }) => {
        beforeEach(() => {
          wrapper = createWrapper(testPageInfo);
        });

        it(`should have button links defined as ${expectedAfter || 'empty'} and
        ${expectedBefore || 'empty'}`, () => {
          const glPagination = wrapper.findComponent(GlKeysetPagination);
          expect(glPagination.props().prevButtonLink).toContain(expectedBefore);
          expect(glPagination.props().nextButtonLink).toContain(expectedAfter);
        });
      },
    );

    describe.each([
      {
        clickEvent: {
          shiftKey: false,
          ctrlKey: false,
          altKey: false,
          metaKey: false,
        },
        isDefaultPrevented: true,
      },
      {
        clickEvent: {
          shiftKey: true,
          ctrlKey: false,
          altKey: false,
          metaKey: false,
        },
        isDefaultPrevented: false,
      },
      {
        clickEvent: {
          shiftKey: false,
          ctrlKey: true,
          altKey: false,
          metaKey: false,
        },
        isDefaultPrevented: false,
      },
      {
        clickEvent: {
          shiftKey: false,
          ctrlKey: false,
          altKey: true,
          metaKey: false,
        },
        isDefaultPrevented: false,
      },
      {
        clickEvent: {
          shiftKey: false,
          ctrlKey: false,
          altKey: false,
          metaKey: true,
        },
        isDefaultPrevented: false,
      },
    ])(
      'when a pagination button is clicked with $clickEvent',
      ({ clickEvent, isDefaultPrevented }) => {
        let clickEventMock;
        beforeEach(() => {
          clickEventMock = { ...clickEvent, preventDefault: jest.fn() };
        });

        it(`should ${isDefaultPrevented ? '' : 'not '}prevent default event`, () => {
          const pagination = wrapper.findComponent(GlKeysetPagination);
          pagination.vm.$emit('click', clickEventMock);
          expect(clickEventMock.preventDefault).toHaveBeenCalledTimes(isDefaultPrevented ? 1 : 0);
        });
      },
    );

    it('should navigate to a correct previous page', () => {
      const pagination = wrapper.findComponent(GlKeysetPagination);
      pagination.vm.$emit('prev', pageInfo.startCursor);
      expect(mockRouter.push).toHaveBeenCalledWith({ query: { before: pageInfo.startCursor } });
    });

    it('should navigate to a correct next page', () => {
      const pagination = wrapper.findComponent(GlKeysetPagination);
      pagination.vm.$emit('next', pageInfo.endCursor);
      expect(mockRouter.push).toHaveBeenCalledWith({ query: { after: pageInfo.endCursor } });
    });
  });
});
