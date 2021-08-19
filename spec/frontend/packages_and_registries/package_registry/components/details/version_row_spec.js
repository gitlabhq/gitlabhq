import { GlLink, GlSprintf, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PackageTags from '~/packages/shared/components/package_tags.vue';
import PublishMethod from '~/packages/shared/components/publish_method.vue';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { packageVersions } from '../../mock_data';

const packageVersion = packageVersions()[0];

describe('VersionRow', () => {
  let wrapper;

  const findListItem = () => wrapper.findComponent(ListItem);
  const findLink = () => wrapper.findComponent(GlLink);
  const findPackageTags = () => wrapper.findComponent(PackageTags);
  const findPublishMethod = () => wrapper.findComponent(PublishMethod);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);

  function createComponent(packageEntity = packageVersion) {
    wrapper = shallowMountExtended(VersionRow, {
      propsData: {
        packageEntity,
      },
      stubs: {
        ListItem,
        GlSprintf,
        GlTruncate,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a link to the version detail', () => {
    createComponent();

    expect(findLink().attributes('href')).toBe(`${getIdFromGraphQLId(packageVersion.id)}`);
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

  describe('disabled status', () => {
    it('disables the list item', () => {
      createComponent({ ...packageVersion, status: 'something' });

      expect(findListItem().props('disabled')).toBe(true);
    });

    it('disables the link', () => {
      createComponent({ ...packageVersion, status: 'something' });

      expect(findLink().attributes('disabled')).toBe('true');
    });
  });
});
