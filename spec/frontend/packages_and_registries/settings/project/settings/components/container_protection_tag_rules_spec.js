import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ContainerProtectionTagRules from '~/packages_and_registries/settings/project/components/container_protection_tag_rules.vue';

describe('ContainerProtectionTagRules', () => {
  let wrapper;
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findDescription = () => wrapper.findByTestId('description');

  const createComponent = () => {
    wrapper = shallowMountExtended(ContainerProtectionTagRules);
  };

  describe('layout', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders card component with title', () => {
      expect(findCrudComponent().props('title')).toBe('Protected container tags');
    });

    it('renders card component with description', () => {
      expect(findDescription().text()).toBe(
        'When a container tag is protected, only certain user roles can update and delete the protected tag, which helps to prevent tampering with the tag. A maximum of 5 protection rules can be added per project.',
      );
    });
  });
});
