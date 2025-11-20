import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HomepagePreferencesBanner from '~/homepage/components/homepage_preferences_banner.vue';

const preferencesPath = '/-/profile/preferences#behavior';

describe(HomepagePreferencesBanner.name, () => {
  let wrapper;

  const findBanner = () => wrapper.findByTestId('homepage-preferences-banner');
  const findPreferencesLink = () => wrapper.findByTestId('go-to-preferences-link');

  const createComponent = (shouldShowCallout = true) => {
    wrapper = shallowMountExtended(HomepagePreferencesBanner, {
      provide: {
        preferencesPath,
      },
      stubs: {
        UserCalloutDismisser: {
          template: `
            <div>
              <slot :should-show-callout="${shouldShowCallout}" :dismiss="() => {}" />
            </div>
            `,
        },
        GlSprintf,
      },
    });
  };

  it('shows the banner', () => {
    createComponent();

    expect(findBanner().exists()).toBe(true);
  });

  it('hides the banner when it has been dismissed', () => {
    createComponent(false);

    expect(findBanner().exists()).toBe(false);
  });

  it('renders a link to the preferences', () => {
    createComponent();

    expect(findPreferencesLink().props('href')).toBe(preferencesPath);
  });
});
