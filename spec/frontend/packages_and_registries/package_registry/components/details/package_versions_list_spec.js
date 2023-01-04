import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PackageVersionsList from '~/packages_and_registries/package_registry/components/details/package_versions_list.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
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
    findRegistryList: () => wrapper.findComponent(RegistryList),
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
      stubs: {
        RegistryList,
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

    it('does not display registry list', () => {
      expect(uiElements.findRegistryList().exists()).toBe(false);
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

    it('does not display registry list', () => {
      expect(uiElements.findRegistryList().exists()).toBe(false);
    });
  });

  describe('when list is loaded with data', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('displays package registry list', () => {
      expect(uiElements.findRegistryList().exists()).toEqual(true);
    });

    it('binds the right props', () => {
      expect(uiElements.findRegistryList().props()).toMatchObject({
        items: packageList,
        pagination: {},
        isLoading: false,
        hiddenDelete: true,
      });
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

    it('emits prev-page event when registry list emits prev event', () => {
      uiElements.findRegistryList().vm.$emit('prev-page');

      expect(wrapper.emitted('prev-page')).toHaveLength(1);
    });

    it('emits next-page when registry list emits next event', () => {
      uiElements.findRegistryList().vm.$emit('next-page');

      expect(wrapper.emitted('next-page')).toHaveLength(1);
    });
  });
});
