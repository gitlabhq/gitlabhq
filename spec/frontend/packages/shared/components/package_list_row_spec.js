import { shallowMount } from '@vue/test-utils';
import PackagesListRow from '~/packages/shared/components/package_list_row.vue';
import PackageTags from '~/packages/shared/components/package_tags.vue';
import PackagePath from '~/packages/shared/components/package_path.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { packageList } from '../../mock_data';

describe('packages_list_row', () => {
  let wrapper;
  let store;

  const [packageWithoutTags, packageWithTags] = packageList;

  const findPackageTags = () => wrapper.find(PackageTags);
  const findPackagePath = () => wrapper.find(PackagePath);
  const findDeleteButton = () => wrapper.find('[data-testid="action-delete"]');
  const findPackageType = () => wrapper.find('[data-testid="package-type"]');

  const mountComponent = ({
    isGroup = false,
    packageEntity = packageWithoutTags,
    showPackageType = true,
    disableDelete = false,
  } = {}) => {
    wrapper = shallowMount(PackagesListRow, {
      store,
      stubs: { ListItem },
      propsData: {
        packageLink: 'foo',
        packageEntity,
        isGroup,
        showPackageType,
        disableDelete,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('tags', () => {
    it('renders package tags when a package has tags', () => {
      mountComponent({ isGroup: false, packageEntity: packageWithTags });

      expect(findPackageTags().exists()).toBe(true);
    });

    it('does not render when there are no tags', () => {
      mountComponent();

      expect(findPackageTags().exists()).toBe(false);
    });
  });

  describe('when is is group', () => {
    beforeEach(() => {
      mountComponent({ isGroup: true });
    });

    it('has a package path component', () => {
      expect(findPackagePath().exists()).toBe(true);
      expect(findPackagePath().props()).toMatchObject({ path: 'foo/bar/baz' });
    });
  });

  describe('showPackageType', () => {
    it('shows the type when set', () => {
      mountComponent();

      expect(findPackageType().exists()).toBe(true);
    });

    it('does not show the type when not set', () => {
      mountComponent({ showPackageType: false });

      expect(findPackageType().exists()).toBe(false);
    });
  });

  describe('deleteAvailable', () => {
    it('does not show when not set', () => {
      mountComponent({ disableDelete: true });

      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('delete event', () => {
    beforeEach(() => mountComponent({ packageEntity: packageWithoutTags }));

    it('emits the packageToDelete event when the delete button is clicked', async () => {
      findDeleteButton().vm.$emit('click');

      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('packageToDelete')).toBeTruthy();
      expect(wrapper.emitted('packageToDelete')[0]).toEqual([packageWithoutTags]);
    });
  });
});
