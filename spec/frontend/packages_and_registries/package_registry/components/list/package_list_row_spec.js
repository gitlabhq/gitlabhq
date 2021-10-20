import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagePath from '~/packages/shared/components/package_path.vue';
import PackageTags from '~/packages/shared/components/package_tags.vue';
import PackageIconAndName from '~/packages/shared/components/package_icon_and_name.vue';
import { PACKAGE_ERROR_STATUS } from '~/packages_and_registries/package_registry/constants';

import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { packageData, packagePipelines, packageProject, packageTags } from '../../mock_data';

describe('packages_list_row', () => {
  let wrapper;

  const defaultProvide = {
    isGroupPage: false,
  };

  const packageWithoutTags = { ...packageData(), project: packageProject() };
  const packageWithTags = { ...packageWithoutTags, tags: { nodes: packageTags() } };

  const findPackageTags = () => wrapper.find(PackageTags);
  const findPackagePath = () => wrapper.find(PackagePath);
  const findDeleteButton = () => wrapper.findByTestId('action-delete');
  const findPackageIconAndName = () => wrapper.find(PackageIconAndName);
  const findListItem = () => wrapper.findComponent(ListItem);
  const findPackageLink = () => wrapper.findComponent(GlLink);
  const findWarningIcon = () => wrapper.findByTestId('warning-icon');
  const findLeftSecondaryInfos = () => wrapper.findByTestId('left-secondary-infos');

  const mountComponent = ({
    packageEntity = packageWithoutTags,
    provide = defaultProvide,
  } = {}) => {
    wrapper = shallowMountExtended(PackagesListRow, {
      provide,
      stubs: {
        ListItem,
        GlSprintf,
      },
      propsData: {
        packageEntity,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('tags', () => {
    it('renders package tags when a package has tags', () => {
      mountComponent({ packageEntity: packageWithTags });

      expect(findPackageTags().exists()).toBe(true);
    });

    it('does not render when there are no tags', () => {
      mountComponent();

      expect(findPackageTags().exists()).toBe(false);
    });
  });

  describe('when it is group', () => {
    it('has a package path component', () => {
      mountComponent({ provide: { isGroupPage: true } });

      expect(findPackagePath().exists()).toBe(true);
      expect(findPackagePath().props()).toMatchObject({ path: 'gitlab-org/gitlab-test' });
    });
  });

  describe('delete button', () => {
    it('exists and has the correct props', () => {
      mountComponent({ packageEntity: packageWithoutTags });

      expect(findDeleteButton().exists()).toBe(true);
      expect(findDeleteButton().attributes()).toMatchObject({
        icon: 'remove',
        category: 'secondary',
        variant: 'danger',
        title: 'Remove package',
      });
    });

    it('emits the packageToDelete event when the delete button is clicked', async () => {
      mountComponent({ packageEntity: packageWithoutTags });

      findDeleteButton().vm.$emit('click');

      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('packageToDelete')).toBeTruthy();
      expect(wrapper.emitted('packageToDelete')[0]).toEqual([packageWithoutTags]);
    });
  });

  describe(`when the package is in ${PACKAGE_ERROR_STATUS} status`, () => {
    beforeEach(() => {
      mountComponent({ packageEntity: { ...packageWithoutTags, status: PACKAGE_ERROR_STATUS } });
    });

    it('list item has a disabled prop', () => {
      expect(findListItem().props('disabled')).toBe(true);
    });

    it('details link is disabled', () => {
      expect(findPackageLink().attributes('disabled')).toBe('true');
    });

    it('has a warning icon', () => {
      const icon = findWarningIcon();
      const tooltip = getBinding(icon.element, 'gl-tooltip');
      expect(icon.props('icon')).toBe('warning');
      expect(tooltip.value).toMatchObject({
        title: 'Invalid Package: failed metadata extraction',
      });
    });

    it('delete button does not exist', () => {
      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('secondary left info', () => {
    it('has the package version', () => {
      mountComponent();

      expect(findLeftSecondaryInfos().text()).toContain(packageWithoutTags.version);
    });

    it('if the pipeline exists show the author message', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
      });

      expect(findLeftSecondaryInfos().text()).toContain('published by Administrator');
    });

    it('has icon and name component', () => {
      mountComponent();

      expect(findPackageIconAndName().text()).toBe(packageWithoutTags.packageType.toLowerCase());
    });
  });
});
