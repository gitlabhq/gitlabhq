import { shallowMount } from '@vue/test-utils';
import DependencyRow from '~/packages/details/components/dependency_row.vue';
import { dependencyLinks } from '../../mock_data';

describe('DependencyRow', () => {
  let wrapper;

  const { withoutFramework, withoutVersion, fullLink } = dependencyLinks;

  function createComponent({ dependencyLink = fullLink } = {}) {
    wrapper = shallowMount(DependencyRow, {
      propsData: {
        dependency: dependencyLink,
      },
    });
  }

  const dependencyVersion = () => wrapper.find('[data-testid="version-pattern"]');
  const dependencyFramework = () => wrapper.find('[data-testid="target-framework"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders', () => {
    it('full dependency', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('version', () => {
    it('does not render any version information when not supplied', () => {
      createComponent({ dependencyLink: withoutVersion });

      expect(dependencyVersion().exists()).toBe(false);
    });

    it('does render version info when it exists', () => {
      createComponent();

      expect(dependencyVersion().exists()).toBe(true);
      expect(dependencyVersion().text()).toBe(fullLink.version_pattern);
    });
  });

  describe('target framework', () => {
    it('does not render any framework information when not supplied', () => {
      createComponent({ dependencyLink: withoutFramework });

      expect(dependencyFramework().exists()).toBe(false);
    });

    it('does render framework info when it exists', () => {
      createComponent();

      expect(dependencyFramework().exists()).toBe(true);
      expect(dependencyFramework().text()).toBe(`(${fullLink.target_framework})`);
    });
  });
});
