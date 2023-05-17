import { GlListboxItem, GlCollapsibleListbox, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { allEnvironments, ENVIRONMENT_QUERY_LIMIT } from '~/ci/ci_variable_list/constants';
import CiEnvironmentsDropdown from '~/ci/ci_variable_list/components/ci_environments_dropdown.vue';

describe('Ci environments dropdown', () => {
  let wrapper;

  const envs = ['dev', 'prod', 'staging'];
  const defaultProps = {
    areEnvironmentsLoading: false,
    environments: envs,
    selectedEnvironmentScope: '',
  };

  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findListboxItemByIndex = (index) => wrapper.findAllComponents(GlListboxItem).at(index);
  const findActiveIconByIndex = (index) => findListboxItemByIndex(index).findComponent(GlIcon);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxText = () => findListbox().props('toggleText');
  const findCreateWildcardButton = () => wrapper.findComponent(GlDropdownItem);
  const findMaxEnvNote = () => wrapper.findByTestId('max-envs-notice');

  const createComponent = ({ props = {}, searchTerm = '', enableFeatureFlag = false } = {}) => {
    wrapper = mountExtended(CiEnvironmentsDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        glFeatures: {
          ciLimitEnvironmentScope: enableFeatureFlag,
        },
      },
    });

    findListbox().vm.$emit('search', searchTerm);
  };

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
    describe.each`
      featureFlag | flagStatus    | defaultEnvStatus      | firstItemValue | envIndices
      ${true}     | ${'enabled'}  | ${'prepends'}         | ${'*'}         | ${[1, 2, 3]}
      ${false}    | ${'disabled'} | ${'does not prepend'} | ${envs[0]}     | ${[0, 1, 2]}
    `(
      'when ciLimitEnvironmentScope feature flag is $flagStatus',
      ({ featureFlag, defaultEnvStatus, firstItemValue, envIndices }) => {
        beforeEach(() => {
          createComponent({ props: { environments: envs }, enableFeatureFlag: featureFlag });
        });

        it(`${defaultEnvStatus} * in listbox`, () => {
          expect(findListboxItemByIndex(0).text()).toBe(firstItemValue);
        });

        it('renders all environments', () => {
          expect(findListboxItemByIndex(envIndices[0]).text()).toBe(envs[0]);
          expect(findListboxItemByIndex(envIndices[1]).text()).toBe(envs[1]);
          expect(findListboxItemByIndex(envIndices[2]).text()).toBe(envs[2]);
        });

        it('does not display active checkmark', () => {
          expect(findActiveIconByIndex(0).classes('gl-visibility-hidden')).toBe(true);
        });
      },
    );
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

  describe('When ciLimitEnvironmentScope feature flag is disabled', () => {
    const currentEnv = envs[2];

    beforeEach(() => {
      createComponent();
    });

    it('filters on the frontend and renders only the environment searched for', async () => {
      await findListbox().vm.$emit('search', currentEnv);

      expect(findAllListboxItems()).toHaveLength(1);
      expect(findListboxItemByIndex(0).text()).toBe(currentEnv);
    });

    it('does not emit event when searching', async () => {
      expect(wrapper.emitted('search-environment-scope')).toBeUndefined();

      await findListbox().vm.$emit('search', currentEnv);

      expect(wrapper.emitted('search-environment-scope')).toBeUndefined();
    });

    it('does not display note about max environments shown', () => {
      expect(findMaxEnvNote().exists()).toBe(false);
    });
  });

  describe('When ciLimitEnvironmentScope feature flag is enabled', () => {
    const currentEnv = envs[2];

    beforeEach(() => {
      createComponent({ enableFeatureFlag: true });
    });

    it('renders environments passed down to it', async () => {
      await findListbox().vm.$emit('search', currentEnv);

      expect(findAllListboxItems()).toHaveLength(envs.length);
    });

    it('emits event when searching', async () => {
      expect(wrapper.emitted('search-environment-scope')).toHaveLength(1);

      await findListbox().vm.$emit('search', currentEnv);

      expect(wrapper.emitted('search-environment-scope')).toHaveLength(2);
      expect(wrapper.emitted('search-environment-scope')[1]).toEqual([currentEnv]);
    });

    it('renders loading icon while search query is loading', () => {
      createComponent({ enableFeatureFlag: true, props: { areEnvironmentsLoading: true } });

      expect(findListbox().props('searching')).toBe(true);
    });

    it('displays note about max environments shown', () => {
      expect(findMaxEnvNote().exists()).toBe(true);
      expect(findMaxEnvNote().text()).toContain(String(ENVIRONMENT_QUERY_LIMIT));
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
