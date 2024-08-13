import { GlAlert, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import WebIdeOAuthApplicationCallout, {
  I18N_WEB_IDE_OAUTH_APPLICATION_CALLOUT,
} from '~/ide/components/oauth_application_callout.vue';
import ResetApplicationSettingsModal from '~/ide/components/reset_application_settings_modal.vue';

const MOCK_IDE_REDIRECT_PATH = '/ide/oauth_redirect';
const MOCK_IDE_RESET_APPLICATION_SETTINGS_PATH = '/ide/reset_application_settings';

describe('WebIdeOAuthApplicationCallout', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(ResetApplicationSettingsModal);

  const createWrapper = () => {
    wrapper = mount(WebIdeOAuthApplicationCallout, {
      propsData: {
        redirectUrlPath: MOCK_IDE_REDIRECT_PATH,
        resetApplicationSettingsPath: MOCK_IDE_RESET_APPLICATION_SETTINGS_PATH,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('renders alert', () => {
    expect(findAlert().exists()).toBe(true);
    expect(findButton().text()).toBe(I18N_WEB_IDE_OAUTH_APPLICATION_CALLOUT.alertButtonText);
  });

  it('shows reset application settings modal on restore button click', async () => {
    findButton().vm.$emit('click');
    await nextTick();
    const modal = findModal();
    expect(modal.exists()).toBe(true);
    expect(modal.props('visible')).toBe(true);
  });

  it.each(['close', 'cancel'])(
    'hides reset application settings modal on close or cancel',
    async (eventName) => {
      findModal().vm.$emit(eventName);
      await nextTick();

      const modal = findModal();
      expect(modal.exists()).toBe(true);
      expect(modal.props('visible')).toBe(false);
    },
  );
});
