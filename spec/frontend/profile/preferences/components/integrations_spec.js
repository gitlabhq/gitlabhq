import { shallowMount } from '@vue/test-utils';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import ProfilePreferencesIntegrations from '~/profile/preferences/components/integrations.vue';
import ExtensionsMarketplaceWarning from '~/profile/preferences/components/extensions_marketplace_warning.vue';
import {
  INTEGRATION_EXTENSIONS_MARKETPLACE,
  INTEGRATION_VIEW_CONFIGS,
} from '~/profile/preferences/constants';
import { integrationViews, userFields } from '../mock_data';

describe('ProfilePreferencesIntegrations component', () => {
  let wrapper;

  const extensionsMarketplaceView = {
    name: INTEGRATION_EXTENSIONS_MARKETPLACE,
    help_link: 'http://foo.com/help-extensions-marketplace',
    message: 'Click %{linkStart}Foo%{linkEnd}!',
    message_url: 'http://foo.com',
  };

  function createComponent(provide = {}) {
    wrapper = shallowMount(ProfilePreferencesIntegrations, {
      provide: {
        integrationViews,
        userFields: { ...userFields, gitpod_enabled: true },
        ...provide,
      },
    });
  }

  const findIntegrationViews = () => wrapper.findAllComponents(IntegrationView);
  const findWarning = () => wrapper.findComponent(ExtensionsMarketplaceWarning);

  it('renders one integration view per integration, bound to the user fields', () => {
    createComponent();

    expect(findIntegrationViews()).toHaveLength(integrationViews.length);

    const [sourcegraph, gitpod] = findIntegrationViews().wrappers;
    expect(sourcegraph.props()).toMatchObject({
      config: INTEGRATION_VIEW_CONFIGS.sourcegraph,
      value: false,
      helpLink: integrationViews[0].help_link,
      message: integrationViews[0].message,
      messageUrl: integrationViews[0].message_url,
    });
    expect(gitpod.props()).toMatchObject({
      config: INTEGRATION_VIEW_CONFIGS.gitpod,
      value: true,
    });
  });

  it('does not render the extensions marketplace warning without that integration', () => {
    createComponent();

    expect(findWarning().exists()).toBe(false);
  });

  describe('with the extensions marketplace integration', () => {
    beforeEach(() => {
      createComponent({ integrationViews: [extensionsMarketplaceView] });
    });

    it('renders the view with a 2-way-bound value', async () => {
      const integrationView = wrapper.findComponent(IntegrationView);

      expect(integrationView.props()).toMatchObject({
        value: false,
        config: INTEGRATION_VIEW_CONFIGS[INTEGRATION_EXTENSIONS_MARKETPLACE],
      });

      await integrationView.vm.$emit('input', true);

      expect(integrationView.props('value')).toBe(true);
    });

    it('renders the warning with a 2-way-bound value', async () => {
      expect(findWarning().props()).toEqual({
        helpUrl: extensionsMarketplaceView.help_link,
        value: false,
      });

      await findWarning().vm.$emit('input', true);

      expect(findWarning().props('value')).toBe(true);
      expect(wrapper.findComponent(IntegrationView).props('value')).toBe(true);
    });
  });
});
