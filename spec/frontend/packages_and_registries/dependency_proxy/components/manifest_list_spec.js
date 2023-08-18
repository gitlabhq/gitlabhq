import { GlKeysetPagination, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ManifestRow from '~/packages_and_registries/dependency_proxy/components/manifest_row.vue';
import ManifestsEmptyState from '~/packages_and_registries/dependency_proxy/components/manifests_empty_state.vue';
import Component from '~/packages_and_registries/dependency_proxy/components/manifests_list.vue';
import {
  proxyData,
  proxyManifests,
  pagination,
} from 'jest/packages_and_registries/dependency_proxy/mock_data';

describe('Manifests List', () => {
  let wrapper;

  const defaultProps = {
    dependencyProxyImagePrefix: proxyData().dependencyProxyImagePrefix,
    manifests: proxyManifests(),
    pagination: pagination(),
    loading: false,
  };

  const createComponent = (propsData = defaultProps) => {
    wrapper = shallowMountExtended(Component, {
      propsData,
    });
  };

  const findEmptyState = () => wrapper.findComponent(ManifestsEmptyState);
  const findRows = () => wrapper.findAllComponents(ManifestRow);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findMainArea = () => wrapper.findByTestId('main-area');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  it('has the correct title', () => {
    createComponent();

    expect(wrapper.text()).toContain(Component.i18n.listTitle);
  });

  it('shows a row for every manifest', () => {
    createComponent();

    expect(findRows()).toHaveLength(defaultProps.manifests.length);
  });

  it('does not show the empty state component', () => {
    createComponent();

    expect(findEmptyState().exists()).toBe(false);
  });

  it('binds a manifest to each row', () => {
    createComponent();

    expect(findRows().at(0).props('manifest')).toBe(defaultProps.manifests[0]);
  });

  it('binds a dependencyProxyImagePrefix to each row', () => {
    createComponent();

    expect(findRows().at(0).props('dependencyProxyImagePrefix')).toBe(
      proxyData().dependencyProxyImagePrefix,
    );
  });

  describe('loading', () => {
    it.each`
      loading  | expectLoader | expectContent
      ${false} | ${false}     | ${true}
      ${true}  | ${true}      | ${false}
    `('when loading is $loading', ({ loading, expectLoader, expectContent }) => {
      createComponent({ ...defaultProps, loading });

      expect(findSkeletonLoader().exists()).toBe(expectLoader);
      expect(findMainArea().exists()).toBe(expectContent);
    });
  });

  describe('when there are no manifests', () => {
    beforeEach(() => {
      createComponent({ ...defaultProps, manifests: [], pagination: {} });
    });

    it('shows the empty state component', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('hides the list', () => {
      expect(findRows()).toHaveLength(0);
    });
  });

  describe('pagination', () => {
    it('has the correct props', () => {
      createComponent();

      const { __typename, ...paginationProps } = defaultProps.pagination;
      expect(findPagination().props()).toMatchObject(paginationProps);
    });

    it('emits the next-page event', () => {
      createComponent();

      findPagination().vm.$emit('next');

      expect(wrapper.emitted('next-page')).toEqual([[]]);
    });

    it('emits the prev-page event', () => {
      createComponent();

      findPagination().vm.$emit('prev');

      expect(wrapper.emitted('prev-page')).toEqual([[]]);
    });
  });
});
