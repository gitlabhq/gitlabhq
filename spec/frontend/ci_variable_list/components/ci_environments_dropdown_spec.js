import { GlListboxItem, GlCollapsibleListbox, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { allEnvironments } from '~/ci_variable_list/constants';
import CiEnvironmentsDropdown from '~/ci_variable_list/components/ci_environments_dropdown.vue';

describe('Ci environments dropdown', () => {
  let wrapper;

  const envs = ['dev', 'prod', 'staging'];
  const defaultProps = { environments: envs, selectedEnvironmentScope: '' };

  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findListboxItemByIndex = (index) => wrapper.findAllComponents(GlListboxItem).at(index);
  const findActiveIconByIndex = (index) => findListboxItemByIndex(index).findComponent(GlIcon);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxText = () => findListbox().props('toggleText');
  const findCreateWildcardButton = () => wrapper.findComponent(GlDropdownItem);

  const createComponent = ({ props = {}, searchTerm = '' } = {}) => {
    wrapper = mount(CiEnvironmentsDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });

    findListbox().vm.$emit('search', searchTerm);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('No environments found', () => {
    beforeEach(() => {
      createComponent({ searchTerm: 'stable' });
    });

    it('renders create button with search term if environments do not contain search term', () => {
      const button = findCreateWildcardButton();
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Create wildcard: stable');
    });
  });

  describe('Search term is empty', () => {
    beforeEach(() => {
      createComponent({ props: { environments: envs } });
    });

    it('renders all environments when search term is empty', () => {
      expect(findListboxItemByIndex(0).text()).toBe(envs[0]);
      expect(findListboxItemByIndex(1).text()).toBe(envs[1]);
      expect(findListboxItemByIndex(2).text()).toBe(envs[2]);
    });

    it('does not display active checkmark on the inactive stage', () => {
      expect(findActiveIconByIndex(0).classes('gl-visibility-hidden')).toBe(true);
    });
  });

  describe('when `*` is the value of selectedEnvironmentScope props', () => {
    const wildcardScope = '*';

    beforeEach(() => {
      createComponent({ props: { selectedEnvironmentScope: wildcardScope } });
    });

    it('shows the `All environments` text and not the wildcard', () => {
      expect(findListboxText()).toContain(allEnvironments.text);
      expect(findListboxText()).not.toContain(wildcardScope);
    });
  });

  describe('Environments found', () => {
    const currentEnv = envs[2];

    beforeEach(() => {
      createComponent({ searchTerm: currentEnv });
    });

    it('renders only the environment searched for', () => {
      expect(findAllListboxItems()).toHaveLength(1);
      expect(findListboxItemByIndex(0).text()).toBe(currentEnv);
    });

    it('does not display create button', () => {
      expect(findCreateWildcardButton().exists()).toBe(false);
    });

    describe('Custom events', () => {
      describe('when selecting an environment', () => {
        const itemIndex = 0;

        beforeEach(() => {
          createComponent();
        });

        it('emits `select-environment` when an environment is clicked', () => {
          findListbox().vm.$emit('select', envs[itemIndex]);
          expect(wrapper.emitted('select-environment')).toEqual([[envs[itemIndex]]]);
        });
      });

      describe('when creating a new environment from a search term', () => {
        const search = 'new-env';
        beforeEach(() => {
          createComponent({ searchTerm: search });
        });

        it('emits create-environment-scope', () => {
          findCreateWildcardButton().vm.$emit('click');
          expect(wrapper.emitted('create-environment-scope')).toEqual([[search]]);
        });
      });
    });
  });
});
