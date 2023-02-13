import { GlIcon, GlLink, GlSprintf, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMethod from '~/packages_and_registries/shared/components/publish_method.vue';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { PACKAGE_ERROR_STATUS } from '~/packages_and_registries/package_registry/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import { packageVersions } from '../../mock_data';

const packageVersion = packageVersions()[0];

describe('VersionRow', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);
  const findPackageTags = () => wrapper.findComponent(PackageTags);
  const findPublishMethod = () => wrapper.findComponent(PublishMethod);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findPackageName = () => wrapper.findComponent(GlTruncate);
  const findWarningIcon = () => wrapper.findComponent(GlIcon);

  function createComponent(packageEntity = packageVersion) {
    wrapper = shallowMountExtended(VersionRow, {
      propsData: {
        packageEntity,
      },
      stubs: {
        GlSprintf,
        GlTruncate,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('has a link to the version detail', () => {
    createComponent();

    expect(findLink().attributes('href')).toBe(`${getIdFromGraphQLId(packageVersion.id)}`);
  });

  it('lists the package name', () => {
    createComponent();

    expect(findLink().text()).toBe(packageVersion.name);
  });

  it('has the version of the package', () => {
    createComponent();

    expect(wrapper.text()).toContain(packageVersion.version);
  });

  it('has a package tags component', () => {
    createComponent();

    expect(findPackageTags().props('tags')).toBe(packageVersion.tags.nodes);
  });

  it('has a publish method component', () => {
    createComponent();

    expect(findPublishMethod().props('packageEntity')).toBe(packageVersion);
  });
  it('has a time-ago tooltip', () => {
    createComponent();

    expect(findTimeAgoTooltip().props('time')).toBe(packageVersion.createdAt);
  });

  describe(`when the package is in ${PACKAGE_ERROR_STATUS} status`, () => {
    beforeEach(() => {
      createComponent({
        ...packageVersion,
        status: PACKAGE_ERROR_STATUS,
        _links: {
          webPath: null,
        },
      });
    });

    it('lists the package name', () => {
      expect(findPackageName().props('text')).toBe('@gitlab-org/package-15');
    });

    it('does not have a link to navigate to the details page', () => {
      expect(findLink().exists()).toBe(false);
    });

    it('has a warning icon', () => {
      const icon = findWarningIcon();
      const tooltip = getBinding(icon.element, 'gl-tooltip');
      expect(icon.props('name')).toBe('warning');
      expect(icon.props('ariaLabel')).toBe('Warning');
      expect(tooltip.value).toMatchObject({
        title: 'Invalid Package: failed metadata extraction',
      });
    });
  });

  describe('disabled status', () => {
    beforeEach(() => {
      createComponent({
        ...packageVersion,
        status: 'something',
        _links: {
          webPath: null,
        },
      });
    });

    it('lists the package name', () => {
      expect(findPackageName().props('text')).toBe('@gitlab-org/package-15');
    });

    it('does not have a link to navigate to the details page', () => {
      expect(findLink().exists()).toBe(false);
    });
  });
});
