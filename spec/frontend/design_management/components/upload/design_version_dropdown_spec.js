import { GlDropdown, GlDropdownItem, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DesignVersionDropdown from '~/design_management/components/upload/design_version_dropdown.vue';
import mockAllVersions from './mock_data/all_versions';

const LATEST_VERSION_ID = 3;
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
      stubs: { GlSprintf },
    });

    wrapper.setData({
      allVersions: maxVersions > -1 ? mockAllVersions.slice(0, maxVersions) : mockAllVersions,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findVersionLink = (index) => wrapper.findAll(GlDropdownItem).at(index);

  it('renders design version dropdown button', () => {
    createComponent();

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('renders design version list', () => {
    createComponent();

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('selected version name', () => {
    it('has "latest" on most recent version item', () => {
      createComponent();

      return wrapper.vm.$nextTick().then(() => {
        expect(findVersionLink(0).text()).toContain('latest');
      });
    });
  });

  describe('versions list', () => {
    it('displays latest version text by default', () => {
      createComponent();

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlDropdown).attributes('text')).toBe('Showing latest version');
      });
    });

    it('displays latest version text when only 1 version is present', () => {
      createComponent({ maxVersions: 1 });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlDropdown).attributes('text')).toBe('Showing latest version');
      });
    });

    it('displays version text when the current version is not the latest', () => {
      createComponent({ $route: designRouteFactory(PREVIOUS_VERSION_ID) });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlDropdown).attributes('text')).toBe(`Showing version #1`);
      });
    });

    it('displays latest version text when the current version is the latest', () => {
      createComponent({ $route: designRouteFactory(LATEST_VERSION_ID) });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlDropdown).attributes('text')).toBe('Showing latest version');
      });
    });

    it('should have the same length as apollo query', () => {
      createComponent();

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.findAll(GlDropdownItem)).toHaveLength(wrapper.vm.allVersions.length);
      });
    });
  });
});
