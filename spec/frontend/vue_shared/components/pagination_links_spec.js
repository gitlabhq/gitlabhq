import { mount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import {
  PREV,
  NEXT,
  LABEL_FIRST_PAGE,
  LABEL_PREV_PAGE,
  LABEL_NEXT_PAGE,
  LABEL_LAST_PAGE,
} from '~/vue_shared/components/pagination/constants';

describe('Pagination links component', () => {
  const pageInfo = {
    page: 3,
    perPage: 5,
    total: 30,
  };
  const translations = {
    prevText: PREV,
    nextText: NEXT,
    labelFirstPage: LABEL_FIRST_PAGE,
    labelPrevPage: LABEL_PREV_PAGE,
    labelNextPage: LABEL_NEXT_PAGE,
    labelLastPage: LABEL_LAST_PAGE,
  };

  let wrapper;
  let glPagination;
  let changeMock;

  const createComponent = () => {
    changeMock = jest.fn();
    wrapper = mount(PaginationLinks, {
      propsData: {
        change: changeMock,
        pageInfo,
      },
      sync: false,
    });
  };

  beforeEach(() => {
    createComponent();
    glPagination = wrapper.find(GlPagination);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should provide translated text to GitLab UI pagination', () => {
    Object.entries(translations).forEach(entry => {
      expect(glPagination.vm[entry[0]]).toBe(entry[1]);
    });
  });

  it('should call change when page changes', () => {
    wrapper.find('a').trigger('click');
    expect(changeMock).toHaveBeenCalled();
  });

  it('should pass page from pageInfo to GitLab UI pagination', () => {
    expect(glPagination.vm.value).toBe(pageInfo.page);
  });

  it('should pass per page from pageInfo to GitLab UI pagination', () => {
    expect(glPagination.vm.perPage).toBe(pageInfo.perPage);
  });

  it('should pass total items from pageInfo to GitLab UI pagination', () => {
    expect(glPagination.vm.totalItems).toBe(pageInfo.total);
  });
});
