import { GlDropdown, GlDropdownItem, GlIcon, GlSearchBoxByType } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { allEnvironments } from '~/ci_variable_list/constants';
import CiEnvironmentsDropdown from '~/ci_variable_list/components/ci_environments_dropdown.vue';

describe('Ci environments dropdown', () => {
  let wrapper;

  const envs = ['dev', 'prod', 'staging'];
  const defaultProps = { environments: envs, selectedEnvironmentScope: '' };

  const findDropdownText = () => wrapper.findComponent(GlDropdown).text();
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemByIndex = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);
  const findActiveIconByIndex = (index) => findDropdownItemByIndex(index).findComponent(GlIcon);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  const createComponent = ({ props = {}, searchTerm = '' } = {}) => {
    wrapper = mount(CiEnvironmentsDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });

    findSearchBox().vm.$emit('input', searchTerm);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('No environments found', () => {
    beforeEach(() => {
      createComponent({ searchTerm: 'stable' });
    });

    it('renders create button with search term if environments do not contain search term', () => {
      expect(findAllDropdownItems()).toHaveLength(2);
      expect(findDropdownItemByIndex(1).text()).toBe('Create wildcard: stable');
    });

    it('renders empty results message', () => {
      expect(findDropdownItemByIndex(0).text()).toBe('No matching results');
    });
  });

  describe('Search term is empty', () => {
    beforeEach(() => {
      createComponent({ props: { environments: envs } });
    });

    it('renders all environments when search term is empty', () => {
      expect(findAllDropdownItems()).toHaveLength(3);
      expect(findDropdownItemByIndex(0).text()).toBe(envs[0]);
      expect(findDropdownItemByIndex(1).text()).toBe(envs[1]);
      expect(findDropdownItemByIndex(2).text()).toBe(envs[2]);
    });

    it('should not display active checkmark on the inactive stage', () => {
      expect(findActiveIconByIndex(0).classes('gl-visibility-hidden')).toBe(true);
    });
  });

  describe('when `*` is the value of selectedEnvironmentScope props', () => {
    const wildcardScope = '*';

    beforeEach(() => {
      createComponent({ props: { selectedEnvironmentScope: wildcardScope } });
    });

    it('shows the `All environments` text and not the wildcard', () => {
      expect(findDropdownText()).toContain(allEnvironments.text);
      expect(findDropdownText()).not.toContain(wildcardScope);
    });
  });

  describe('Environments found', () => {
    const currentEnv = envs[2];

    beforeEach(async () => {
      createComponent({ searchTerm: currentEnv });
      await nextTick();
    });

    it('renders only the environment searched for', () => {
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe(currentEnv);
    });

    it('should not display create button', () => {
      const environments = findAllDropdownItems().filter((env) => env.text().startsWith('Create'));
      expect(environments).toHaveLength(0);
      expect(findAllDropdownItems()).toHaveLength(1);
    });

    it('should not display empty results message', () => {
      expect(wrapper.findComponent({ ref: 'noMatchingResults' }).exists()).toBe(false);
    });

    it('should clear the search term when showing the dropdown', () => {
      wrapper.findComponent(GlDropdown).trigger('click');

      expect(findSearchBox().text()).toBe('');
    });

    describe('Custom events', () => {
      describe('when clicking on an environment', () => {
        const itemIndex = 0;

        beforeEach(() => {
          createComponent();
        });

        it('should emit `select-environment` if an environment is clicked', async () => {
          await nextTick();

          await findDropdownItemByIndex(itemIndex).vm.$emit('click');

          expect(wrapper.emitted('select-environment')).toEqual([[envs[itemIndex]]]);
        });
      });

      describe('when creating a new environment from a search term', () => {
        const search = 'new-env';
        beforeEach(() => {
          createComponent({ searchTerm: search });
        });

        it('should emit createClicked if an environment is clicked', async () => {
          await nextTick();
          findDropdownItemByIndex(1).vm.$emit('click');
          expect(wrapper.emitted('create-environment-scope')).toEqual([[search]]);
        });
      });
    });
  });
});
