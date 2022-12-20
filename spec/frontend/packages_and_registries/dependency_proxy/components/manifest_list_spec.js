import { GlKeysetPagination } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ManifestRow from '~/packages_and_registries/dependency_proxy/components/manifest_row.vue';

import Component from '~/packages_and_registries/dependency_proxy/components/manifests_list.vue';
import {
  proxyManifests,
  pagination,
} from 'jest/packages_and_registries/dependency_proxy/mock_data';

describe('Manifests List', () => {
  let wrapper;

  const defaultProps = {
    manifests: proxyManifests(),
    pagination: pagination(),
  };

  const createComponent = (propsData = defaultProps) => {
    wrapper = shallowMountExtended(Component, {
      propsData,
    });
  };

  const findRows = () => wrapper.findAllComponents(ManifestRow);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  afterEach(() => {
    wrapper.destroy();
  });

  it('has the correct title', () => {
    createComponent();

    expect(wrapper.text()).toContain(Component.i18n.listTitle);
  });

  it('shows a row for every manifest', () => {
    createComponent();

    expect(findRows().length).toBe(defaultProps.manifests.length);
  });

  it('binds a manifest to each row', () => {
    createComponent();

    expect(findRows().at(0).props()).toMatchObject({
      manifest: defaultProps.manifests[0],
    });
  });

  describe('pagination', () => {
    it('is hidden when there is no next or prev pages', () => {
      createComponent({ ...defaultProps, pagination: {} });

      expect(findPagination().exists()).toBe(false);
    });

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
