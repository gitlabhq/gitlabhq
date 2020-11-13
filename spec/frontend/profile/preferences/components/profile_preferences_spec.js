import { shallowMount } from '@vue/test-utils';

import ProfilePreferences from '~/profile/preferences/components/profile_preferences.vue';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import { integrationViews, userFields } from '../mock_data';

describe('ProfilePreferences component', () => {
  let wrapper;
  const defaultProvide = {
    integrationViews: [],
    userFields,
  };

  function createComponent(options = {}) {
    const { props = {}, provide = {} } = options;
    return shallowMount(ProfilePreferences, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      propsData: props,
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should not render Integrations section', () => {
    wrapper = createComponent();
    const views = wrapper.findAll(IntegrationView);
    const divider = wrapper.find('[data-testid="profile-preferences-integrations-rule"]');
    const heading = wrapper.find('[data-testid="profile-preferences-integrations-heading"]');

    expect(divider.exists()).toBe(false);
    expect(heading.exists()).toBe(false);
    expect(views).toHaveLength(0);
  });

  it('should render Integration section', () => {
    wrapper = createComponent({ provide: { integrationViews } });
    const divider = wrapper.find('[data-testid="profile-preferences-integrations-rule"]');
    const heading = wrapper.find('[data-testid="profile-preferences-integrations-heading"]');
    const views = wrapper.findAll(IntegrationView);

    expect(divider.exists()).toBe(true);
    expect(heading.exists()).toBe(true);
    expect(views).toHaveLength(integrationViews.length);
  });

  it('should render ProfilePreferences properly', () => {
    wrapper = createComponent({ provide: { integrationViews } });

    expect(wrapper.element).toMatchSnapshot();
  });
});
