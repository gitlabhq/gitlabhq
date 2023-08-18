import { GlKeysetPagination } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersistedPagination from '~/packages_and_registries/shared/components/persisted_pagination.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

describe('Persisted Search', () => {
  let wrapper;

  const defaultProps = {
    pagination: {
      hasNextPage: true,
      hasPreviousPage: true,
      startCursor: 'eyJpZCI6IjI2In0',
      endCursor: 'eyJpZCI6IjgifQ',
    },
  };

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findUrlSync = () => wrapper.findComponent(UrlSync);

  const mountComponent = ({ propsData = defaultProps, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(PersistedPagination, {
      propsData,
      stubs: {
        UrlSync,
        ...stubs,
      },
    });
  };

  it('has pagination component', () => {
    mountComponent();

    const { hasNextPage, hasPreviousPage, startCursor, endCursor } = defaultProps.pagination;
    expect(findPagination().props('hasNextPage')).toBe(hasNextPage);
    expect(findPagination().props('hasPreviousPage')).toBe(hasPreviousPage);
    expect(findPagination().props('startCursor')).toBe(startCursor);
    expect(findPagination().props('endCursor')).toBe(endCursor);
  });

  it('has a UrlSync component', () => {
    mountComponent();

    expect(findUrlSync().exists()).toBe(true);
  });

  describe('pagination events', () => {
    const updateQueryMock = jest.fn();
    const mockUrlSync = {
      methods: {
        updateQuery: updateQueryMock,
      },
      render() {
        return this.$scopedSlots.default?.({ updateQuery: this.updateQuery });
      },
    };

    beforeEach(() => {
      mountComponent({ stubs: { UrlSync: mockUrlSync } });
    });

    afterEach(() => {
      updateQueryMock.mockReset();
    });

    describe('prev event', () => {
      beforeEach(() => {
        findPagination().vm.$emit('prev');
      });

      it('calls updateQuery mock with right params', () => {
        expect(updateQueryMock).toHaveBeenCalledWith({
          before: defaultProps.pagination?.startCursor,
          after: null,
        });
      });

      it('re-emits prev event', () => {
        expect(wrapper.emitted('prev')).toHaveLength(1);
      });
    });

    describe('next event', () => {
      beforeEach(() => {
        findPagination().vm.$emit('next');
      });

      it('calls updateQuery mock with right params', () => {
        expect(updateQueryMock).toHaveBeenCalledWith({
          after: defaultProps.pagination.endCursor,
          before: null,
        });
      });

      it('re-emits next event', () => {
        expect(wrapper.emitted('next')).toHaveLength(1);
      });
    });
  });
});
