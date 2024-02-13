import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LanguageSwitcherApp from '~/language_switcher/components/app.vue';
import { PREFERRED_LANGUAGE_COOKIE_KEY, EN } from '~/language_switcher/constants';
import * as utils from '~/lib/utils/common_utils';
import { locales, ES } from '../mock_data';

jest.mock('~/lib/utils/common_utils');

describe('<LanguageSwitcher />', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(LanguageSwitcherApp, {
      provide: {
        locales,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const getPreferredLanguage = () => wrapper.find('.gl-new-dropdown-button-text').text();
  const findLanguageDropdownItem = (code) => wrapper.findByTestId(`language_switcher_lang_${code}`);
  const findFooter = () => wrapper.findByTestId('footer');

  it('sets English as preferred language by default', () => {
    expect(getPreferredLanguage()).toBe(EN.text);
  });

  it('sets preferred locale when provided', () => {
    createComponent({
      preferredLocale: ES,
    });

    expect(getPreferredLanguage()).toBe(ES.text);
  });

  it('switches language', async () => {
    // because window.location is **READ ONLY** we cannot simply use
    // jest.spyOn to mock it.
    const originalLocation = window.location;
    delete window.location;
    window.location = {};
    window.location.reload = jest.fn();
    const reloadSpy = window.location.reload;
    expect(reloadSpy).not.toHaveBeenCalled();
    expect(utils.setCookie).not.toHaveBeenCalled();

    const es = findLanguageDropdownItem(ES.value);

    await es.trigger('click');

    expect(reloadSpy).toHaveBeenCalled();
    expect(utils.setCookie).toHaveBeenCalledWith(PREFERRED_LANGUAGE_COOKIE_KEY, ES.value);
    window.location = originalLocation;
  });

  it('renders footer link', () => {
    const link = findFooter().findComponent(GlLink);

    // Assert against actual value so we can implicitly test `helpPagePath` call
    expect(link.attributes('href')).toBe('/help/development/i18n/translation.md');
    expect(link.text()).toBe(LanguageSwitcherApp.HELP_TRANSLATE_MSG);
  });
});
