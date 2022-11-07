import { GlKeysetPagination } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PackageVersionsList from '~/packages_and_registries/package_registry/components/details/package_versions_list.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import { packageData } from '../../mock_data';

describe('PackageVersionsList', () => {
  let wrapper;

  const EmptySlotStub = { name: 'empty-slot-stub', template: '<div>empty message</div>' };
  const packageList = [
    packageData({
      name: 'version 1',
    }),
    packageData({
      id: `gid://gitlab/Packages::Package/112`,
      name: 'version 2',
    }),
  ];

  const uiElements = {
    findLoader: () => wrapper.findComponent(PackagesListLoader),
    findListPagination: () => wrapper.findComponent(GlKeysetPagination),
    findEmptySlot: () => wrapper.findComponent(EmptySlotStub),
    findListRow: () => wrapper.findAllComponents(VersionRow),
  };
  const mountComponent = (props) => {
    wrapper = shallowMountExtended(PackageVersionsList, {
      propsData: {
        versions: packageList,
        pageInfo: {},
        isLoading: false,
        ...props,
      },
      slots: {
        'empty-state': EmptySlotStub,
      },
    });
  };

  describe('when list is loading', () => {
    beforeEach(() => {
      mountComponent({ isLoading: true, versions: [] });
    });
    it('displays loader', () => {
      expect(uiElements.findLoader().exists()).toBe(true);
    });

    it('does not display rows', () => {
      expect(uiElements.findListRow().exists()).toBe(false);
    });

    it('does not display empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(false);
    });

    it('does not display pagination', () => {
      expect(uiElements.findListPagination().exists()).toBe(false);
    });
  });

  describe('when list is loaded and has no data', () => {
    beforeEach(() => {
      mountComponent({ isLoading: false, versions: [] });
    });

    it('displays empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(true);
    });

    it('does not display loader', () => {
      expect(uiElements.findLoader().exists()).toBe(false);
    });

    it('does not display rows', () => {
      expect(uiElements.findListRow().exists()).toBe(false);
    });

    it('does not display pagination', () => {
      expect(uiElements.findListPagination().exists()).toBe(false);
    });
  });

  describe('when list is loaded with data', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('displays package version rows', () => {
      expect(uiElements.findListRow().exists()).toEqual(true);
      expect(uiElements.findListRow()).toHaveLength(packageList.length);
    });

    it('binds the correct props', () => {
      expect(uiElements.findListRow().at(0).props()).toMatchObject({
        packageEntity: expect.objectContaining(packageList[0]),
      });

      expect(uiElements.findListRow().at(1).props()).toMatchObject({
        packageEntity: expect.objectContaining(packageList[1]),
      });
    });

    describe('pagination display', () => {
      it('does not display pagination if there is no previous or next page', () => {
        expect(uiElements.findListPagination().exists()).toBe(false);
      });

      it('displays pagination if pageInfo.hasNextPage is true', async () => {
        await wrapper.setProps({ pageInfo: { hasNextPage: true } });
        expect(uiElements.findListPagination().exists()).toBe(true);
      });

      it('displays pagination if pageInfo.hasPreviousPage is true', async () => {
        await wrapper.setProps({ pageInfo: { hasPreviousPage: true } });
        expect(uiElements.findListPagination().exists()).toBe(true);
      });

      it('displays pagination if both pageInfo.hasNextPage and pageInfo.hasPreviousPage are true', async () => {
        await wrapper.setProps({ pageInfo: { hasNextPage: true, hasPreviousPage: true } });
        expect(uiElements.findListPagination().exists()).toBe(true);
      });
    });

    it('does not display loader', () => {
      expect(uiElements.findLoader().exists()).toBe(false);
    });

    it('does not display empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(false);
    });
  });

  describe('when user interacts with pagination', () => {
    beforeEach(() => {
      mountComponent({ pageInfo: { hasNextPage: true } });
    });

    it('emits prev-page event when paginator emits prev event', () => {
      uiElements.findListPagination().vm.$emit('prev');

      expect(wrapper.emitted('prev-page')).toHaveLength(1);
    });

    it('emits next-page when paginator emits next event', () => {
      uiElements.findListPagination().vm.$emit('next');

      expect(wrapper.emitted('next-page')).toHaveLength(1);
    });
  });
});
