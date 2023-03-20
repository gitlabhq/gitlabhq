import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DependencyRow from '~/packages_and_registries/package_registry/components/details/dependency_row.vue';
import { dependencyLinks } from '../../mock_data';

describe('DependencyRow', () => {
  let wrapper;

  const [fullDependencyLink] = dependencyLinks();
  const { dependency, metadata } = fullDependencyLink;

  function createComponent(dependencyLink = fullDependencyLink) {
    wrapper = shallowMountExtended(DependencyRow, {
      propsData: {
        dependencyLink,
      },
    });
  }

  const dependencyVersion = () => wrapper.findByTestId('version-pattern');
  const dependencyFramework = () => wrapper.findByTestId('target-framework');

  describe('renders', () => {
    it('full dependency', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('version', () => {
    it('does not render any version information when not supplied', () => {
      createComponent({
        ...fullDependencyLink,
        dependency: { ...dependency, versionPattern: undefined },
      });

      expect(dependencyVersion().exists()).toBe(false);
    });

    it('does render version info when it exists', () => {
      createComponent();

      expect(dependencyVersion().exists()).toBe(true);
      expect(dependencyVersion().text()).toBe(dependency.versionPattern);
    });
  });

  describe('target framework', () => {
    it('does not render any framework information when not supplied', () => {
      createComponent({
        ...fullDependencyLink,
        metadata: { ...metadata, targetFramework: undefined },
      });

      expect(dependencyFramework().exists()).toBe(false);
    });

    it('does render framework info when it exists', () => {
      createComponent();

      expect(dependencyFramework().exists()).toBe(true);
      expect(dependencyFramework().text()).toBe(`(${metadata.targetFramework})`);
    });
  });
});
