import { GlBadge, GlFormCheckbox, GlButton, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { keyBy } from 'lodash-es';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ScopeSelector from '~/personal_access_tokens/components/create_legacy_token/scope_selector.vue';

describe('ScopeSelector', () => {
  let wrapper;

  const newGranularPatPath = '/-/user_settings/personal_access_tokens/new';

  const AVAILABLE_SCOPES = [
    { value: 'api', text: 'Full API access' },
    { value: 'read_api', text: 'Read API' },
    { value: 'ai_features', text: 'AI features' },
    { value: 'read_repository', text: 'Read repository' },
    { value: 'write_repository', text: 'Write repository' },
    { value: 'read_virtual_registry', text: 'Read virtual registry' },
    { value: 'write_virtual_registry', text: 'Write virtual registry' },
    { value: 'create_runner', text: 'Create runner' },
    { value: 'manage_runner', text: 'Manage runner' },
    { value: 'read_service_ping', text: 'Read service ping' },
    { value: 'read_user', text: 'Read user' },
    { value: 'self_rotate', text: 'Self rotate' },
    { value: 'k8s_proxy', text: 'Kubernetes proxy' },
    { value: 'admin_mode', text: 'Admin mode' },
    { value: 'sudo', text: 'Sudo' },
  ];
  const SCOPES_LOOKUP = keyBy(AVAILABLE_SCOPES, 'value');

  const createWrapper = ({
    availableScopes = AVAILABLE_SCOPES,
    selectedScopes = [],
    isValid = true,
  } = {}) => {
    wrapper = shallowMountExtended(ScopeSelector, {
      propsData: {
        availableScopes,
        selectedScopes,
        isValid,
        newGranularPatPath,
      },
      stubs: { GlSprintf },
    });
  };

  const findErrorMessage = () => wrapper.findByTestId('error-message');
  const findFieldsets = () => wrapper.findAll('fieldset');
  const findLegends = () => wrapper.findAll('legend');
  const findScopeLi = (scope) => wrapper.findByTestId(scope);
  const findScopeCheckbox = (scope) => findScopeLi(scope).findComponent(GlFormCheckbox);
  const findScopeInfoButton = (scope) => findScopeLi(scope).findComponent(GlButton);
  const findScopePopover = (scope) => findScopeLi(scope).findComponent(GlPopover);
  const findScopeBadge = (scope) => findScopeLi(scope).findComponent(GlBadge);
  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findBadges = () => wrapper.findAllComponents(GlBadge);

  const NON_API_SCOPES = Object.keys(SCOPES_LOOKUP).filter((scope) => scope !== 'api');

  const getCheckedScopes = () =>
    findCheckboxes()
      .wrappers.filter((checkbox) => checkbox.props('checked'))
      .map((checkbox) => checkbox.text());

  const getEnabledScopes = () =>
    findCheckboxes()
      .wrappers.filter((checkbox) => !checkbox.props('disabled'))
      .map((checkbox) => checkbox.text());

  const getScopeDescription = (scope) => SCOPES_LOOKUP[scope].text;
  const toggleScopeCheckbox = (scope) => findScopeCheckbox(scope).vm.$emit('change');

  describe('heading and description', () => {
    beforeEach(() => createWrapper());

    it('shows heading', () => {
      expect(wrapper.find('h2').text()).toBe('Set token scope');
    });

    it('shows description', () => {
      expect(wrapper.find('p').text()).toBe(
        'Scopes set the permission levels granted to the token. Learn more.',
      );
    });

    it('shows link to help page', () => {
      expect(wrapper.findComponent(GlLink).props()).toMatchObject({
        href: '/help/user/profile/personal_access_tokens#personal-access-token-scopes',
        target: '_blank',
      });
    });
  });

  describe('error message', () => {
    it('does not show when isValid props is true', () => {
      createWrapper({ isValid: true });

      expect(findErrorMessage().exists()).toBe(false);
    });

    it('shows message when isValid prop is false', () => {
      createWrapper({ isValid: false });

      expect(findErrorMessage().text()).toBe('At least one scope is required.');
    });
  });

  describe('when all scopes are available', () => {
    beforeEach(() => createWrapper());

    it('shows the expected number of categories', () => {
      expect(findFieldsets()).toHaveLength(7);
    });

    describe.each`
      index | categoryName               | scopes
      ${0}  | ${''}                      | ${['api', 'read_api']}
      ${1}  | ${'AI'}                    | ${['ai_features']}
      ${2}  | ${'Repository'}            | ${['read_repository', 'write_repository']}
      ${3}  | ${'Registry'}              | ${['read_virtual_registry', 'write_virtual_registry']}
      ${4}  | ${'Runners'}               | ${['create_runner', 'manage_runner']}
      ${5}  | ${'Service ping'}          | ${['read_service_ping']}
      ${6}  | ${'User & Administration'} | ${['read_user', 'self_rotate', 'k8s_proxy', 'admin_mode', 'sudo']}
    `('for category "$categoryName"', ({ index, categoryName, scopes }) => {
      let fieldset;

      beforeEach(() => {
        fieldset = findFieldsets().at(index);
      });

      it('shows the category name', () => {
        expect(fieldset.find('legend').text()).toBe(categoryName);
      });

      it('shows expected scope count', () => {
        expect(fieldset.findAll('li')).toHaveLength(scopes.length);
      });

      describe.each(scopes)('for scope "%s"', (scope) => {
        it('shows checkbox', () => {
          expect(findScopeCheckbox(scope).text()).toBe(scope);
        });

        it('shows info button', () => {
          const infoButton = findScopeInfoButton(scope);

          expect(infoButton.props()).toMatchObject({
            icon: 'information-o',
            category: 'tertiary',
          });
          expect(infoButton.attributes()).toMatchObject({
            id: `scope-${scope}`,
            'aria-label': getScopeDescription(scope),
          });
        });

        it('has popover with description text', () => {
          const popover = findScopePopover(scope);

          expect(popover.text()).toContain(getScopeDescription(scope));
          expect(popover.attributes('delay')).toBe('0');
          expect(popover.props()).toMatchObject({
            target: `scope-${scope}`,
            triggers: 'focus',
            title: scope,
            placement: 'auto',
            showCloseButton: true,
          });
        });

        it('does not show broad access badge', () => {
          expect(findScopeBadge(scope).exists()).toBe(false);
        });
      });
    });

    describe('for api scope', () => {
      it('shows additional text in popover', () => {
        expect(findScopePopover('api').text()).toContain(
          'To limit access, use a fine-grained personal access token instead.',
        );
      });

      it('shows link to granular PAT page in popover', () => {
        const link = findScopePopover('api').findComponent(GlLink);

        expect(link.attributes('href')).toBe(newGranularPatPath);
      });

      it('shows broad access badge for API scope when it is selected', () => {
        createWrapper({ selectedScopes: ['api'] });
        const badge = findScopeBadge('api');

        expect(badge.text()).toBe('Broad access');
        expect(badge.props()).toMatchObject({ icon: 'warning', variant: 'warning' });
      });
    });

    describe.each(NON_API_SCOPES)('for scope %s', (scope) => {
      it('does not show additional text in popover', () => {
        expect(findScopePopover(scope).find('p').exists()).toBe(false);
      });

      it('does not show broad access badge when api scope is selected', async () => {
        await wrapper.setProps({ selectedScopes: ['api'] });

        expect(findScopeBadge(scope).exists()).toBe(false);
      });
    });
  });

  describe('category handling', () => {
    it('shows unknown scopes under "Other" category', () => {
      createWrapper({
        availableScopes: [{ value: 'custom_scope', text: 'Custom scope' }],
      });

      expect(findFieldsets()).toHaveLength(1);
      expect(findLegends().at(0).text()).toBe('Other');
      expect(findCheckboxes()).toHaveLength(1);
      expect(findCheckboxes().at(0).text()).toBe('custom_scope');
    });

    it('only shows categories with at least 1 scope', () => {
      createWrapper({
        availableScopes: [
          { value: 'ai_features', text: 'AI features' },
          { value: 'read_repository', text: 'Read repository' },
        ],
      });

      expect(findFieldsets()).toHaveLength(2);
      expect(findLegends().wrappers.map((w) => w.text())).toEqual(['AI', 'Repository']);
    });
  });

  describe('checkbox state', () => {
    beforeEach(() => {
      createWrapper({ selectedScopes: ['create_runner', 'read_user'] });
    });

    it('enables all checkboxes', () => {
      expect(getEnabledScopes()).toEqual(Object.keys(SCOPES_LOOKUP));
    });

    it('checks selected scopes', () => {
      expect(getCheckedScopes()).toEqual(['create_runner', 'read_user']);
    });

    describe('when api scope becomes selected', () => {
      beforeEach(() => wrapper.setProps({ selectedScopes: ['api'] }));

      it('checks only the api scope', () => {
        expect(getCheckedScopes()).toEqual(['api']);
      });

      it('disables all other checkboxes', () => {
        expect(getEnabledScopes()).toEqual(['api']);
      });
    });

    describe('when api scope becomes unselected', () => {
      beforeEach(async () => {
        await wrapper.setProps({ selectedScopes: ['api'] });
        await wrapper.setProps({ selectedScopes: [] });
      });

      it('re-enables all checkboxes', () => {
        expect(getEnabledScopes()).toEqual(Object.keys(SCOPES_LOOKUP));
      });

      it('removes the broad access badge', () => {
        expect(findBadges()).toHaveLength(0);
      });
    });
  });

  describe('checkbox toggling behavior', () => {
    beforeEach(() => {
      createWrapper({ selectedScopes: ['create_runner', 'read_user'] });
    });

    it('emits expected scopes when scope is selected', () => {
      toggleScopeCheckbox('ai_features');

      expect(wrapper.emitted('change')[0][0]).toEqual([
        'create_runner',
        'read_user',
        'ai_features',
      ]);
    });

    it('emits expected scopes when scope is unselected', () => {
      toggleScopeCheckbox('create_runner');

      expect(wrapper.emitted('change')[0][0]).toEqual(['read_user']);
    });

    it('emits only api scope when api scope is selected', () => {
      toggleScopeCheckbox('api');

      expect(wrapper.emitted('change')[0][0]).toEqual(['api']);
    });

    it('emits empty scopes when api scope is unselected', () => {
      createWrapper({ selectedScopes: ['api'] });
      toggleScopeCheckbox('api');

      expect(wrapper.emitted('change')[0][0]).toEqual([]);
    });
  });
});
