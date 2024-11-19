import { GlFormCheckbox, GlSprintf, GlTruncate, GlBadge } from '@gitlab/ui';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { RouterLinkStub } from '@vue/test-utils';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMessage from '~/packages_and_registries/shared/components/publish_message.vue';
import PublishMethod from '~/packages_and_registries/package_registry/components/list/publish_method.vue';
import {
  PACKAGE_ERROR_STATUS,
  PACKAGE_DEPRECATED_STATUS,
} from '~/packages_and_registries/package_registry/constants';

import ListItem from '~/vue_shared/components/registry/list_item.vue';
import {
  linksData,
  packageData,
  packagePipelines,
  packageProject,
  packageTags,
} from '../../mock_data';

Vue.use(VueRouter);

describe('packages_list_row', () => {
  let wrapper;

  const defaultProvide = {
    isGroupPage: false,
    canDeletePackages: true,
  };

  const packageWithoutTags = { ...packageData(), project: packageProject(), ...linksData };
  const packageWithTags = { ...packageWithoutTags, tags: { nodes: packageTags() } };

  const findPackageTags = () => wrapper.findComponent(PackageTags);
  const findDeprecatedBadge = () => wrapper.findComponent(GlBadge);
  const findDeleteDropdown = () => wrapper.findByTestId('delete-dropdown');
  const findDeleteButton = () => wrapper.findByTestId('action-delete');
  const findErrorMessage = () => wrapper.findByTestId('error-message');
  const findPackageType = () => wrapper.findByTestId('package-type');
  const findPackageLink = () => wrapper.findByTestId('details-link');
  const findWarningIcon = () => wrapper.findByTestId('warning-icon');
  const findLeftSecondaryInfos = () => wrapper.findByTestId('left-secondary-infos');
  const findPackageVersion = () => findLeftSecondaryInfos().findComponent(GlTruncate);
  const findPublishMessage = () => wrapper.findComponent(PublishMessage);
  const findPublishMethod = () => wrapper.findComponent(PublishMethod);
  const findListItem = () => wrapper.findComponent(ListItem);
  const findBulkDeleteAction = () => wrapper.findComponent(GlFormCheckbox);
  const findPackageName = () => wrapper.findByTestId('package-name');

  const mountComponent = ({
    packageEntity = packageWithoutTags,
    selected = false,
    provide = defaultProvide,
  } = {}) => {
    wrapper = shallowMountExtended(PackagesListRow, {
      provide,
      stubs: {
        ListItem,
        GlSprintf,
        RouterLink: RouterLinkStub,
        GlBadge,
      },
      propsData: {
        packageEntity,
        selected,
      },
    });
  };

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a link to navigate to the details page', () => {
    mountComponent();

    expect(findPackageLink().props()).toMatchObject({
      to: { name: 'details', params: { id: getIdFromGraphQLId(packageWithoutTags.id) } },
    });
  });

  it('lists the package name', () => {
    mountComponent();

    expect(findPackageName().text()).toBe('@gitlab-org/package-15');
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

  describe('delete dropdown', () => {
    it('does not exist when package cannot be destroyed', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, userPermissions: { destroyPackage: false } },
      });

      expect(findDeleteDropdown().exists()).toBe(false);
    });

    it('exists when package can be destroyed', () => {
      mountComponent();

      expect(findDeleteDropdown().props()).toMatchObject({
        category: 'tertiary',
        icon: 'ellipsis_v',
        textSrOnly: true,
        noCaret: true,
        toggleText: 'More actions',
      });
    });
  });

  describe('delete button', () => {
    it('does not exist when package cannot be destroyed', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, userPermissions: { destroyPackage: false } },
      });

      expect(findDeleteButton().exists()).toBe(false);
    });

    it('exists and has the correct text', () => {
      mountComponent({ packageEntity: packageWithoutTags });

      expect(findDeleteButton().exists()).toBe(true);
      expect(findDeleteButton().text()).toBe('Delete package');
    });

    it('emits the delete event when the delete button is clicked', () => {
      mountComponent({ packageEntity: packageWithoutTags });

      findDeleteButton().vm.$emit('action');

      expect(wrapper.emitted('delete')).toHaveLength(1);
    });
  });

  describe(`when the package is in ${PACKAGE_ERROR_STATUS} status`, () => {
    beforeEach(() => {
      mountComponent({
        packageEntity: {
          ...packageWithoutTags,
          status: PACKAGE_ERROR_STATUS,
          _links: {
            webPath: null,
          },
        },
      });
    });

    it('lists the package name', () => {
      expect(findPackageName().text()).toBe('@gitlab-org/package-15');
    });

    it('does not show the publish method', () => {
      expect(findPublishMethod().exists()).toBe(false);
    });

    it('does not show published message', () => {
      expect(findPublishMessage().exists()).toBe(false);
    });

    it('does not have a link to navigate to the details page', () => {
      expect(findPackageLink().exists()).toBe(false);
    });

    it('has a warning icon', () => {
      const icon = findWarningIcon();
      expect(icon.props('name')).toBe('warning');
    });

    it('renders error message text', () => {
      expect(findErrorMessage().text()).toEqual(
        'Error publishing · Invalid Package: failed metadata extraction',
      );
    });

    describe('with custom error message', () => {
      it('renders error message text', () => {
        mountComponent({
          packageEntity: {
            ...packageWithoutTags,
            status: PACKAGE_ERROR_STATUS,
            statusMessage: 'custom error message',
            _links: {
              webPath: null,
            },
          },
        });

        expect(findErrorMessage().text()).toEqual('Error publishing · custom error message');
      });
    });

    it('has a delete dropdown', () => {
      expect(findDeleteDropdown().exists()).toBe(true);
    });
  });

  describe('left action template', () => {
    it('does not render checkbox if not permitted', () => {
      mountComponent({
        provide: {
          ...defaultProvide,
          canDeletePackages: false,
        },
      });

      expect(findBulkDeleteAction().exists()).toBe(false);
    });

    it('renders checkbox', () => {
      mountComponent();

      expect(findBulkDeleteAction().exists()).toBe(true);
      expect(findBulkDeleteAction().attributes('checked')).toBeUndefined();
    });

    it('emits select when checked', () => {
      mountComponent();

      findBulkDeleteAction().vm.$emit('change');

      expect(wrapper.emitted('select')).toHaveLength(1);
    });

    it('renders checkbox in selected state if selected', () => {
      mountComponent({
        selected: true,
      });

      expect(findBulkDeleteAction().attributes('checked')).toBe('true');
      expect(findListItem().props()).toMatchObject({
        selected: true,
      });
    });
  });

  describe('secondary left info', () => {
    it('has the package version', () => {
      mountComponent();

      expect(findPackageVersion().props()).toMatchObject({
        text: packageWithoutTags.version,
        withTooltip: true,
      });
    });

    it('has package type with middot', () => {
      mountComponent();

      expect(findPackageType().text()).toBe(`· ${packageWithoutTags.packageType.toLowerCase()}`);
    });
  });

  describe('right info', () => {
    const projectPageProps = {
      projectName: '',
      projectUrl: '',
      publishDate: packageWithoutTags.createdAt,
    };

    it('has publish method component', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
      });

      expect(findPublishMethod().props('pipeline')).toEqual(packagePipelines()[0]);
    });

    it('if the package is published through CI sets author on PublishMessage component', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
      });

      expect(findPublishMessage().props()).toStrictEqual({
        author: 'Administrator',
        ...projectPageProps,
      });
    });

    it('if the package is published manually then does not set author on PublishMessage component', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags },
      });

      expect(findPublishMessage().props()).toStrictEqual({
        author: '',
        ...projectPageProps,
      });
    });

    describe('PublishMessage component for group page', () => {
      const groupPageProps = {
        projectName: packageWithoutTags.project.name,
        projectUrl: packageWithoutTags.project.webUrl,
        publishDate: packageWithoutTags.createdAt,
      };

      it('if the package is published through CI sets project name, url and author', () => {
        mountComponent({
          provide: {
            ...defaultProvide,
            isGroupPage: true,
          },
          packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
        });

        expect(findPublishMessage().props()).toStrictEqual({
          author: 'Administrator',
          ...groupPageProps,
        });
      });

      it('if the package is published manually passes show project name, url and does not set author', () => {
        mountComponent({
          provide: {
            ...defaultProvide,
            isGroupPage: true,
          },
          packageEntity: { ...packageWithoutTags },
        });

        expect(findPublishMessage().props()).toStrictEqual({
          author: '',
          ...groupPageProps,
        });
      });
    });
  });

  describe('badge "protected"', () => {
    const mountComponentForBadgeProtected = ({ packageEntityProtectionRuleExists = true } = {}) =>
      mountComponent({
        packageEntity: {
          ...packageWithoutTags,
          protectionRuleExists: packageEntityProtectionRuleExists,
        },
        provide: {
          ...defaultProvide,
        },
      });

    const findProtectedBadge = () => wrapper.findComponent(ProtectedBadge);

    describe('when package is protected', () => {
      it('shows badge', () => {
        mountComponentForBadgeProtected();

        expect(findProtectedBadge().exists()).toBe(true);
        expect(findProtectedBadge().props('tooltipText')).toMatch(
          'A protection rule exists for this package.',
        );
      });
    });

    describe('when package is not protected', () => {
      it('does not show badge', () => {
        mountComponentForBadgeProtected({ packageEntityProtectionRuleExists: false });

        expect(findProtectedBadge().exists()).toBe(false);
      });
    });
  });

  describe('deprecated badge', () => {
    it('is not rendered by default', () => {
      mountComponent();

      expect(findDeprecatedBadge().exists()).toBe(false);
    });

    describe('when package has deprecated status', () => {
      beforeEach(() => {
        mountComponent({
          packageEntity: {
            ...packageWithoutTags,
            status: PACKAGE_DEPRECATED_STATUS,
          },
        });
      });

      it('renders GlBadge component', () => {
        expect(findDeprecatedBadge().props('variant')).toBe('warning');
      });

      it('renders the text `deprecated`', () => {
        expect(findDeprecatedBadge().text()).toBe('deprecated');
      });
    });
  });
});
