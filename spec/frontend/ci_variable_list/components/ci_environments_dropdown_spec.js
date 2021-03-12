import { GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import CiEnvironmentsDropdown from '~/ci_variable_list/components/ci_environments_dropdown.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Ci environments dropdown', () => {
  let wrapper;
  let store;

  const enterSearchTerm = (value) =>
    wrapper.find('[data-testid="ci-environment-search"]').setValue(value);

  const createComponent = (term) => {
    store = new Vuex.Store({
      getters: {
        joinedEnvironments: () => ['dev', 'prod', 'staging'],
      },
    });

    wrapper = mount(CiEnvironmentsDropdown, {
      store,
      localVue,
      propsData: {
        value: term,
      },
    });
    enterSearchTerm(term);
  };

  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemByIndex = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);
  const findActiveIconByIndex = (index) => findDropdownItemByIndex(index).findComponent(GlIcon);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('No environments found', () => {
    beforeEach(() => {
      createComponent('stable');
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
      createComponent('');
    });

    it('renders all environments when search term is empty', () => {
      expect(findAllDropdownItems()).toHaveLength(3);
      expect(findDropdownItemByIndex(0).text()).toBe('dev');
      expect(findDropdownItemByIndex(1).text()).toBe('prod');
      expect(findDropdownItemByIndex(2).text()).toBe('staging');
    });

    it('should not display active checkmark on the inactive stage', () => {
      expect(findActiveIconByIndex(0).classes('gl-visibility-hidden')).toBe(true);
    });
  });

  describe('Environments found', () => {
    beforeEach(async () => {
      createComponent('prod');
      await wrapper.vm.$nextTick();
    });

    it('renders only the environment searched for', () => {
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe('prod');
    });

    it('should not display create button', () => {
      const environments = findAllDropdownItems().filter((env) => env.text().startsWith('Create'));
      expect(environments).toHaveLength(0);
      expect(findAllDropdownItems()).toHaveLength(1);
    });

    it('should not display empty results message', () => {
      expect(wrapper.findComponent({ ref: 'noMatchingResults' }).exists()).toBe(false);
    });

    it('should display active checkmark if active', () => {
      expect(findActiveIconByIndex(0).classes('gl-visibility-hidden')).toBe(false);
    });

    it('should clear the search term when showing the dropdown', () => {
      wrapper.findComponent(GlDropdown).trigger('click');

      expect(wrapper.find('[data-testid="ci-environment-search"]').text()).toBe('');
    });

    describe('Custom events', () => {
      it('should emit selectEnvironment if an environment is clicked', () => {
        findDropdownItemByIndex(0).vm.$emit('click');
        expect(wrapper.emitted('selectEnvironment')).toEqual([['prod']]);
      });

      it('should emit createClicked if an environment is clicked', async () => {
        createComponent('newscope');

        await wrapper.vm.$nextTick();
        findDropdownItemByIndex(1).vm.$emit('click');
        expect(wrapper.emitted('createClicked')).toEqual([['newscope']]);
      });
    });
  });
});
