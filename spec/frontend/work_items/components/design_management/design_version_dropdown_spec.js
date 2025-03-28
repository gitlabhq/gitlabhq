import { GlAvatar, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import DesignVersionDropdown from '~/work_items/components/design_management/design_version_dropdown.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { mockAllVersions } from './mock_data';

const LATEST_VERSION_ID = 1;
const PREVIOUS_VERSION_ID = 2;

const designRouteFactory = (versionId) => ({
  path: `?version=${versionId}`,
  query: {
    version: `${versionId}`,
  },
});

const MOCK_ROUTE = {
  path: '/',
  query: {},
};

describe('Design management design version dropdown component', () => {
  const $router = { push: jest.fn() };
  let wrapper;

  function createComponent({ maxVersions = -1, $route = MOCK_ROUTE } = {}) {
    const designVersions =
      maxVersions > -1 ? mockAllVersions.slice(0, maxVersions) : mockAllVersions;

    wrapper = shallowMount(DesignVersionDropdown, {
      propsData: {
        allVersions: designVersions,
      },
      mocks: {
        $route,
        $router,
      },
      stubs: { GlAvatar: true, GlCollapsibleListbox },
    });
  }

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findVersionLink = (index) => wrapper.findAllComponents(GlListboxItem).at(index);

  describe('renders the item with custom template in design version list', () => {
    let listItem;
    const latestVersion = mockAllVersions[0];

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      listItem = findAllListboxItems().at(0);
    });

    it('should render author name and their avatar', () => {
      expect(listItem.findComponent(GlAvatar).props('alt')).toBe(latestVersion.author.name);
      expect(listItem.text()).toContain(latestVersion.author.name);
    });

    it('should render correct version number', () => {
      expect(listItem.text()).toContain('Version 2 (latest)');
    });

    it('should render time ago tooltip', () => {
      expect(listItem.findComponent(TimeAgo).props('time')).toBe(latestVersion.createdAt);
    });
  });

  describe('selected version name', () => {
    it('has "latest" on most recent version item', async () => {
      createComponent();

      await waitForPromises();

      expect(findVersionLink(0).text()).toContain('latest');
    });
  });

  describe('versions list', () => {
    it('displays latest version text by default', async () => {
      createComponent();

      await waitForPromises();

      expect(findListbox().props('toggleText')).toBe('Latest version');
    });

    it('displays latest version text when only 1 version is present', async () => {
      createComponent({ maxVersions: 1 });

      await waitForPromises();

      expect(findListbox().props('toggleText')).toBe('Latest version');
    });

    it('displays version text when the current version is not the latest', async () => {
      createComponent({ $route: designRouteFactory(PREVIOUS_VERSION_ID) });

      await waitForPromises();

      expect(findListbox().props('toggleText')).toBe(`Showing version #1`);
    });

    it('displays latest version text when the current version is the latest', async () => {
      createComponent({ $route: designRouteFactory(LATEST_VERSION_ID) });

      await waitForPromises();

      expect(findListbox().props('toggleText')).toBe('Latest version');
    });

    it('should have the same length as apollo query', async () => {
      createComponent();

      await waitForPromises();

      expect(findAllListboxItems()).toHaveLength(mockAllVersions.length);
    });

    it('should render TimeAgo', async () => {
      createComponent();

      await waitForPromises();

      expect(wrapper.findAllComponents(TimeAgo)).toHaveLength(mockAllVersions.length);
    });

    it('should update the route when a version is selected', async () => {
      const originalLocation = window.location.href;
      setWindowLocation(
        `${originalLocation}?&or%5Blabel_name%5D%5B%5D=bug&or%5Blabel_name%5D%5B%5D=tech%20debt&not%5Blabel_name%5D%5B%5D=documentation&not%5Blabel_name%5D%5B%5D=feature&first_page_size=20&show=foo`,
      );

      createComponent();

      await waitForPromises();

      findListbox().vm.$emit('select', mockAllVersions[1].id);

      expect($router.push).toHaveBeenCalledWith({
        path: MOCK_ROUTE.path,
        query: {
          first_page_size: '20',
          'not[label_name][]': ['documentation', 'feature'],
          'or[label_name][]': ['bug', 'tech debt'],
          show: 'foo',
          version: '2',
        },
      });
    });
  });
});
