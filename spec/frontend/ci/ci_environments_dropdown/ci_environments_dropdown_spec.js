import { GlListboxItem, GlCollapsibleListbox, GlDropdownDivider, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CiEnvironmentsDropdown from '~/ci/common/private/ci_environments_dropdown';

describe('Ci environments dropdown', () => {
  let wrapper;

  const envs = ['DEV', 'PROD', 'STAGING'];
  const defaultProps = {
    isEnvironmentRequired: true,
    areEnvironmentsLoading: false,
    canCreateWildcard: true,
    environments: envs,
    selectedEnvironmentScope: '',
  };

  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findListboxItemByIndex = (index) => wrapper.findAllComponents(GlListboxItem).at(index);
  const findActiveIconByIndex = (index) => findListboxItemByIndex(index).findComponent(GlIcon);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxText = () => findListbox().props('toggleText');
  const findCreateWildcardButton = () => wrapper.findByTestId('create-wildcard-button');
  const findDropdownDivider = () => wrapper.findComponent(GlDropdownDivider);
  const findSearchQueryNote = () => wrapper.findByTestId('search-query-note');

  const createComponent = ({ props = {}, searchTerm = '' } = {}) => {
    wrapper = mountExtended(CiEnvironmentsDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });

    findListbox().vm.$emit('search', searchTerm);
  };

  describe('create wildcard buttons', () => {
    describe('when canCreateWildcard is true and search has wildcard character', () => {
      beforeEach(() => {
        createComponent({ props: { canCreateWildcard: true }, searchTerm: 'stable/*' });
      });

      it('renders create button during search', () => {
        expect(findCreateWildcardButton().exists()).toBe(true);
      });
    });

    describe('when canCreateWildcard is true and wildcard character is missing from search', () => {
      beforeEach(() => {
        createComponent({ props: { canCreateWildcard: true }, searchTerm: 'stable/' });
      });

      it('does not render create button during search', () => {
        expect(findCreateWildcardButton().exists()).toBe(false);
      });
    });

    describe('when canCreateWildcard is false', () => {
      beforeEach(() => {
        createComponent({ props: { canCreateWildcard: false }, searchTerm: 'stable/*' });
      });

      it('does not render create button during search', () => {
        expect(findCreateWildcardButton().exists()).toBe(false);
      });
    });
  });

  describe('No environments found', () => {
    describe('default behavior', () => {
      beforeEach(() => {
        createComponent({ searchTerm: 'stable/*' });
      });

      it('renders dropdown divider', () => {
        expect(findDropdownDivider().exists()).toBe(true);
      });

      it('renders create button with search term if environments do not contain search term', () => {
        const button = findCreateWildcardButton();
        expect(button.exists()).toBe(true);
        expect(button.text()).toBe('Create wildcard: stable/*');
      });
    });
  });

  describe('Search term is empty', () => {
    beforeEach(() => {
      createComponent({ props: { environments: envs } });
    });

    it('prepends * in listbox', () => {
      expect(findListboxItemByIndex(0).text()).toBe('*');
    });

    it('renders all environments', () => {
      expect(findListboxItemByIndex(1).text()).toBe(envs[0]);
      expect(findListboxItemByIndex(2).text()).toBe(envs[1]);
      expect(findListboxItemByIndex(3).text()).toBe(envs[2]);
    });

    it('does not display active checkmark', () => {
      expect(findActiveIconByIndex(0).classes('gl-invisible')).toBe(true);
    });

    describe('when isEnvironmentRequired is false', () => {
      beforeEach(() => {
        createComponent({ props: { isEnvironmentRequired: false, environments: envs } });
      });

      it('adds Not applicable as an option', () => {
        expect(findListboxItemByIndex(1).text()).toBe('Not applicable');
      });
    });
  });

  describe('when `*` is the value of selectedEnvironmentScope props', () => {
    const wildcardScope = '*';

    beforeEach(() => {
      createComponent({ props: { selectedEnvironmentScope: wildcardScope } });
    });

    it('shows the `All environments` text and not the wildcard', () => {
      expect(findListboxText()).toContain('All (default)');
      expect(findListboxText()).not.toContain(wildcardScope);
    });
  });

  describe('when no environment is selected', () => {
    beforeEach(() => {
      createComponent({ props: { selectedEnvironmentScope: '' } });
    });

    it('shows the placeholder text', () => {
      expect(findListboxText()).toContain('Select environment or create wildcard');
    });
  });

  describe('when fetching environments', () => {
    const currentEnv = envs[2];

    beforeEach(() => {
      createComponent();
    });

    it('renders dropdown divider', () => {
      expect(findDropdownDivider().exists()).toBe(true);
    });

    it('renders environments passed down to it', async () => {
      await findListbox().vm.$emit('search', currentEnv);

      expect(findAllListboxItems()).toHaveLength(envs.length);
    });

    it('renders dropdown loading icon while fetch query is loading', () => {
      createComponent({ props: { areEnvironmentsLoading: true } });

      expect(findListbox().props('loading')).toBe(true);
      expect(findListbox().props('searching')).toBe(false);
      expect(findDropdownDivider().exists()).toBe(false);
    });

    it('renders search loading icon while search query is loading and dropdown is open', async () => {
      createComponent({ props: { areEnvironmentsLoading: true } });
      await findListbox().vm.$emit('shown');

      expect(findListbox().props('loading')).toBe(false);
      expect(findListbox().props('searching')).toBe(true);
    });

    it('emits event when searching', async () => {
      expect(wrapper.emitted('search-environment-scope')).toHaveLength(1);

      await findListbox().vm.$emit('search', currentEnv);

      expect(wrapper.emitted('search-environment-scope')).toHaveLength(2);
      expect(wrapper.emitted('search-environment-scope')[1]).toEqual([currentEnv]);
    });

    it('displays note about max environments', () => {
      expect(findSearchQueryNote().text()).toBe(
        'Enter a search query to find more environments, or use * to create a wildcard.',
      );
    });
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

    describe('when creating a new environment scope from a search term', () => {
      const searchTerm = 'new-env-*';
      beforeEach(() => {
        createComponent({ searchTerm });
      });

      it('sets new environment scope as the selected environment scope', async () => {
        findCreateWildcardButton().trigger('click');

        await findListbox().vm.$emit('search', searchTerm);

        expect(findListbox().props('selected')).toBe(searchTerm);
      });

      it('includes new environment scope in search if it matches search term', async () => {
        findCreateWildcardButton().trigger('click');

        await findListbox().vm.$emit('search', searchTerm);

        expect(findAllListboxItems()).toHaveLength(envs.length + 1);
        expect(findListboxItemByIndex(0).text()).toBe(searchTerm);
      });

      it('excludes new environment scope in search if it does not match the search term', async () => {
        findCreateWildcardButton().trigger('click');

        await findListbox().vm.$emit('search', 'not-new-env');

        expect(findAllListboxItems()).toHaveLength(envs.length);
      });
    });
  });
});
