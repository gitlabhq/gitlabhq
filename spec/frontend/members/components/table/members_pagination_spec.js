import { GlPagination } from '@gitlab/ui';
import setWindowLocation from 'helpers/set_window_location_helper';
import { extendedWrapper, mountExtended } from 'helpers/vue_test_utils_helper';
import MembersPagination from '~/members/components/table/members_pagination.vue';
import { pagination as mockPagination } from '../../mock_data';

describe('MembersPagination', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  const findPagination = () => extendedWrapper(wrapper.findComponent(GlPagination));
  const mockURL = 'https://localhost/foo-bar/-/project_members';

  /**
   * Checks if 2nd page link exists and it equals to passed URL
   * @param {string} expectedUrl
   */
  const expectCorrectLinkToPage2 = (expectedUrl) => {
    const secondPageLink = findPagination().findByText('2', { selector: 'a' });
    expect(secondPageLink.exists()).toBe(true);
    expect(secondPageLink.attributes('href')).toBe(expectedUrl);
  };

  const createComponent = ({ pagination = mockPagination, tabQueryParamValue = '' } = {}) => {
    wrapper = mountExtended(MembersPagination, {
      propsData: {
        pagination,
        tabQueryParamValue,
      },
    });
  };

  it('renders `gl-pagination` component with correct props', () => {
    setWindowLocation(mockURL);

    createComponent();

    const glPagination = findPagination();

    expect(glPagination.exists()).toBe(true);
    expect(glPagination.props()).toMatchObject({
      value: mockPagination.currentPage,
      perPage: mockPagination.perPage,
      totalItems: mockPagination.totalItems,
      prevText: 'Previous',
      nextText: 'Next',
      labelNextPage: 'Go to next page',
      labelPrevPage: 'Go to previous page',
      align: 'center',
    });
  });

  it('uses `pagination.paramName` to generate the pagination links', () => {
    setWindowLocation(mockURL);

    createComponent({
      pagination: {
        currentPage: 1,
        perPage: 5,
        totalItems: 10,
        paramName: 'invited_members_page',
      },
    });

    expectCorrectLinkToPage2(`${mockURL}?invited_members_page=2`);
  });

  it('uses tabQueryParamValue to generate the pagination links', () => {
    setWindowLocation(mockURL);

    createComponent({
      tabQueryParamValue: 'invited',
    });

    expectCorrectLinkToPage2(`${mockURL}?tab=invited&page=2`);
  });

  it('removes tab param if tabQueryParamValue is empty', () => {
    setWindowLocation(`${mockURL}?tab=invited`);

    createComponent();

    expectCorrectLinkToPage2(`${mockURL}?page=2`);
  });

  it('removes any URL params defined as `null` in the `params` attribute', () => {
    setWindowLocation(`${mockURL}?search_groups=foo`);

    createComponent({
      pagination: {
        currentPage: 1,
        perPage: 5,
        totalItems: 10,
        paramName: 'page',
        params: { search_groups: null },
      },
    });

    expectCorrectLinkToPage2(`${mockURL}?page=2`);
  });

  describe('no pagination', () => {
    describe.each`
      attribute        | value
      ${'paramName'}   | ${null}
      ${'currentPage'} | ${null}
      ${'perPage'}     | ${null}
      ${'totalItems'}  | ${0}
    `('when pagination.$attribute is $value', ({ attribute, value }) => {
      it('does not render `gl-pagination`', () => {
        createComponent({
          pagination: {
            ...mockPagination,
            [attribute]: value,
          },
        });

        expect(findPagination().exists()).toBe(false);
      });
    });
  });
});
