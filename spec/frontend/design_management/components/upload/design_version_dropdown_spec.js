import { GlAvatar, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DesignVersionDropdown from '~/design_management/components/upload/design_version_dropdown.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import mockAllVersions from './mock_data/all_versions';

const LATEST_VERSION_ID = 1;
const PREVIOUS_VERSION_ID = 2;

const designRouteFactory = (versionId) => ({
  path: `/designs?version=${versionId}`,
  query: {
    version: `${versionId}`,
  },
});

const MOCK_ROUTE = {
  path: '/designs',
  query: {},
};

describe('Design management design version dropdown component', () => {
  let wrapper;

  function createComponent({ maxVersions = -1, $route = MOCK_ROUTE } = {}) {
    wrapper = shallowMount(DesignVersionDropdown, {
      propsData: {
        projectPath: '',
        issueIid: '',
      },
      mocks: {
        $route,
      },
      stubs: { GlAvatar, GlCollapsibleListbox },
    });

    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({
      allVersions: maxVersions > -1 ? mockAllVersions.slice(0, maxVersions) : mockAllVersions,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findVersionLink = (index) => wrapper.findAllComponents(GlListboxItem).at(index);

  it('renders design version dropdown button', async () => {
    createComponent();

    await nextTick();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders design version list', async () => {
    createComponent();

    await nextTick();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('selected version name', () => {
    it('has "latest" on most recent version item', async () => {
      createComponent();

      await nextTick();
      expect(findVersionLink(0).text()).toContain('latest');
    });
  });

  describe('versions list', () => {
    it('displays latest version text by default', async () => {
      createComponent();

      await nextTick();

      expect(findListbox().props('toggleText')).toBe('Showing latest version');
    });

    it('displays latest version text when only 1 version is present', async () => {
      createComponent({ maxVersions: 1 });

      await nextTick();
      expect(findListbox().props('toggleText')).toBe('Showing latest version');
    });

    it('displays version text when the current version is not the latest', async () => {
      createComponent({ $route: designRouteFactory(PREVIOUS_VERSION_ID) });

      await nextTick();
      expect(findListbox().props('toggleText')).toBe(`Showing version #1`);
    });

    it('displays latest version text when the current version is the latest', async () => {
      createComponent({ $route: designRouteFactory(LATEST_VERSION_ID) });

      await nextTick();
      expect(findListbox().props('toggleText')).toBe('Showing latest version');
    });

    it('should have the same length as apollo query', async () => {
      createComponent();

      await nextTick();
      expect(findAllListboxItems()).toHaveLength(wrapper.vm.allVersions.length);
    });

    it('should render TimeAgo', async () => {
      createComponent();

      await nextTick();

      expect(wrapper.findAllComponents(TimeAgo)).toHaveLength(wrapper.vm.allVersions.length);
    });
  });
});
