import { mount, shallowMount } from '@vue/test-utils';
import PackagesListRow from '~/packages/shared/components/package_list_row.vue';
import PackageTags from '~/packages/shared/components/package_tags.vue';
import { packageList } from '../../mock_data';

describe('packages_list_row', () => {
  let wrapper;
  let store;

  const [packageWithoutTags, packageWithTags] = packageList;

  const findPackageTags = () => wrapper.find(PackageTags);
  const findProjectLink = () => wrapper.find('[data-testid="packages-row-project"]');
  const findDeleteButton = () => wrapper.find('[data-testid="action-delete"]');
  const findPackageType = () => wrapper.find('[data-testid="package-type"]');

  const mountComponent = ({
    isGroup = false,
    packageEntity = packageWithoutTags,
    shallow = true,
    showPackageType = true,
    disableDelete = false,
  } = {}) => {
    const mountFunc = shallow ? shallowMount : mount;

    wrapper = mountFunc(PackagesListRow, {
      store,
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

    it('has project field', () => {
      expect(findProjectLink().exists()).toBe(true);
    });

    it('does not show the delete button', () => {
      expect(findDeleteButton().exists()).toBe(false);
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
    beforeEach(() =>
      mountComponent({ isGroup: false, packageEntity: packageWithoutTags, shallow: false }),
    );

    it('emits the packageToDelete event when the delete button is clicked', () => {
      findDeleteButton().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('packageToDelete')).toBeTruthy();
        expect(wrapper.emitted('packageToDelete')[0]).toEqual([packageWithoutTags]);
      });
    });
  });
});
