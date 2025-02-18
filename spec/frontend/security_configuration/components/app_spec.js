import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlTab, GlTabs, GlLink } from '@gitlab/ui';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import stubChildren from 'helpers/stub_children';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import SecurityConfigurationApp from '~/security_configuration/components/app.vue';
import AutoDevopsAlert from '~/security_configuration/components/auto_dev_ops_alert.vue';
import AutoDevopsEnabledAlert from '~/security_configuration/components/auto_dev_ops_enabled_alert.vue';
import { AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY } from '~/security_configuration/constants';
import FeatureCard from '~/security_configuration/components/feature_card.vue';
import SecretPushProtectionFeatureCard from '~/security_configuration/components/secret_push_protection_feature_card.vue';
import TrainingProviderList from '~/security_configuration/components/training_provider_list.vue';
import { securityFeaturesMock, provideMock, secretPushProtectionMock } from '../mock_data';

const gitlabCiHistoryPath = 'test/historyPath';
const { vulnerabilityTrainingDocsPath, projectFullPath } = provideMock;

useLocalStorageSpy();
Vue.use(VueApollo);

const { i18n } = SecurityConfigurationApp;

describe('~/security_configuration/components/app', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const createComponent = ({ shouldShowCallout = true, ...propsData } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = mountExtended(SecurityConfigurationApp, {
      propsData: {
        augmentedSecurityFeatures: securityFeaturesMock,
        securityTrainingEnabled: true,
        ...propsData,
      },
      provide: provideMock,
      stubs: {
        ...stubChildren(SecurityConfigurationApp),
        GlLink: false,
        GlSprintf: false,
        LocalStorageSync: false,
        SectionLayout: false,
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
        PageHeading,
      },
    });
  };

  const findMainHeading = () => wrapper.findByTestId('page-heading');
  const findTab = () => wrapper.findComponent(GlTab);
  const findTabs = () => wrapper.findAllComponents(GlTab);
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findByTestId = (id) => wrapper.findByTestId(id);
  const findFeatureCards = () => wrapper.findAllComponents(FeatureCard);
  const findSecretPushProtection = () => wrapper.findComponent(SecretPushProtectionFeatureCard);
  const findTrainingProviderList = () => wrapper.findComponent(TrainingProviderList);
  const findManageViaMRErrorAlert = () => wrapper.findByTestId('manage-via-mr-error-alert');
  const findLink = ({ href, text, container = wrapper }) => {
    const selector = `a[href="${href}"]`;
    const link = container.find(selector);

    if (link.exists() && link.text() === text) {
      return link;
    }

    return wrapper.find(`${selector} does not exist`);
  };
  const findSecurityViewHistoryLink = () =>
    findLink({
      href: gitlabCiHistoryPath,
      text: i18n.configurationHistory,
      container: findByTestId('security-testing-tab'),
    });

  const findAutoDevopsAlert = () => wrapper.findComponent(AutoDevopsAlert);
  const findAutoDevopsEnabledAlert = () => wrapper.findComponent(AutoDevopsEnabledAlert);
  const findVulnerabilityManagementTab = () => wrapper.findByTestId('vulnerability-management-tab');

  describe('basic structure', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders main-heading with correct text', () => {
      const mainHeading = findMainHeading();
      expect(mainHeading.exists()).toBe(true);
      expect(mainHeading.text()).toContain('Security configuration');
    });

    describe('tabs', () => {
      const expectedTabs = ['security-testing', 'vulnerability-management'];

      it('renders GlTab Component', () => {
        expect(findTab().exists()).toBe(true);
      });

      it('passes the `sync-active-tab-with-query-params` prop', () => {
        expect(findGlTabs().props('syncActiveTabWithQueryParams')).toBe(true);
      });

      it('lazy loads each tab', () => {
        expect(findGlTabs().attributes('lazy')).not.toBe(undefined);
      });

      it('renders correct amount of tabs', () => {
        expect(findTabs()).toHaveLength(expectedTabs.length);
      });

      it.each(expectedTabs)('renders the %s tab', (tabName) => {
        expect(findByTestId(`${tabName}-tab`).exists()).toBe(true);
      });

      it.each(expectedTabs)('has the %s query-param-value', (tabName) => {
        expect(findByTestId(`${tabName}-tab`).props('queryParamValue')).toBe(tabName);
      });
    });

    it('renders right amount of feature cards for given props with correct props', () => {
      const cards = findFeatureCards();
      expect(cards).toHaveLength(1);
      expect(cards.at(0).props()).toEqual({ feature: securityFeaturesMock[0] });
    });

    it('renders a basic description', () => {
      expect(wrapper.text()).toContain(i18n.description);
    });

    it('should not show latest pipeline link when latestPipelinePath is not defined', () => {
      expect(findByTestId('latest-pipeline-info').exists()).toBe(false);
    });

    it('should not show configuration History Link when gitlabCiPresent & gitlabCiHistoryPath are not defined', () => {
      expect(findSecurityViewHistoryLink().exists()).toBe(false);
    });
  });

  describe('Manage via MR Error Alert', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('on initial load', () => {
      it('should  not show Manage via MR Error Alert', () => {
        expect(findManageViaMRErrorAlert().exists()).toBe(false);
      });
    });

    describe('when error occurs', () => {
      const errorMessage = 'There was a manage via MR error';

      it('should show Alert with error Message', async () => {
        expect(findManageViaMRErrorAlert().exists()).toBe(false);
        findFeatureCards().at(0).vm.$emit('error', errorMessage);

        await nextTick();
        expect(findManageViaMRErrorAlert().exists()).toBe(true);
        expect(findManageViaMRErrorAlert().text()).toBe(errorMessage);
      });

      it('should hide Alert when it is dismissed', async () => {
        findFeatureCards().at(0).vm.$emit('error', errorMessage);

        await nextTick();
        expect(findManageViaMRErrorAlert().exists()).toBe(true);

        findManageViaMRErrorAlert().vm.$emit('dismiss');
        await nextTick();
        expect(findManageViaMRErrorAlert().exists()).toBe(false);
      });
    });
  });

  describe('Auto DevOps hint alert', () => {
    describe('given the right props', () => {
      beforeEach(() => {
        createComponent({
          autoDevopsEnabled: false,
          gitlabCiPresent: false,
          canEnableAutoDevops: true,
        });
      });

      it('should show AutoDevopsAlert', () => {
        expect(findAutoDevopsAlert().exists()).toBe(true);
      });

      it('calls the dismiss callback when closing the AutoDevopsAlert', () => {
        expect(userCalloutDismissSpy).not.toHaveBeenCalled();

        findAutoDevopsAlert().vm.$emit('dismiss');

        expect(userCalloutDismissSpy).toHaveBeenCalledTimes(1);
      });
    });

    describe('given the wrong props', () => {
      beforeEach(() => {
        createComponent();
      });
      it('should not show AutoDevopsAlert', () => {
        expect(findAutoDevopsAlert().exists()).toBe(false);
      });
    });
  });

  describe('Auto DevOps enabled alert', () => {
    describe.each`
      context                                        | autoDevopsEnabled | localStorageValue    | shouldRender
      ${'enabled'}                                   | ${true}           | ${null}              | ${true}
      ${'enabled, alert dismissed on other project'} | ${true}           | ${['foo/bar']}       | ${true}
      ${'enabled, alert dismissed on this project'}  | ${true}           | ${[projectFullPath]} | ${false}
      ${'not enabled'}                               | ${false}          | ${null}              | ${false}
    `('given Auto DevOps is $context', ({ autoDevopsEnabled, localStorageValue, shouldRender }) => {
      beforeEach(() => {
        if (localStorageValue !== null) {
          window.localStorage.setItem(
            AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY,
            JSON.stringify(localStorageValue),
          );
        }

        createComponent({
          autoDevopsEnabled,
        });
      });

      it(`${shouldRender ? 'renders' : 'does not render'}`, () => {
        expect(findAutoDevopsEnabledAlert().exists()).toBe(shouldRender);
      });
    });

    describe('dismissing', () => {
      describe.each`
        dismissedProjects    | expectedWrittenValue
        ${null}              | ${[projectFullPath]}
        ${[]}                | ${[projectFullPath]}
        ${['foo/bar']}       | ${['foo/bar', projectFullPath]}
        ${[projectFullPath]} | ${[projectFullPath]}
      `(
        'given dismissed projects $dismissedProjects',
        ({ dismissedProjects, expectedWrittenValue }) => {
          beforeEach(() => {
            if (dismissedProjects !== null) {
              window.localStorage.setItem(
                AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY,
                JSON.stringify(dismissedProjects),
              );
            }

            createComponent({
              augmentedSecurityFeatures: securityFeaturesMock,
              autoDevopsEnabled: true,
            });

            findAutoDevopsEnabledAlert().vm.$emit('dismiss');
          });

          it('adds current project to localStorage value', () => {
            expect(window.localStorage.setItem).toHaveBeenLastCalledWith(
              AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY,
              JSON.stringify(expectedWrittenValue),
            );
          });

          it('hides the alert', () => {
            expect(findAutoDevopsEnabledAlert().exists()).toBe(false);
          });
        },
      );
    });
  });

  describe('when given latestPipelinePath props', () => {
    beforeEach(() => {
      createComponent({
        latestPipelinePath: 'test/path',
      });
    });
  });

  describe('With secret push protection', () => {
    beforeEach(() => {
      createComponent({
        augmentedSecurityFeatures: [secretPushProtectionMock],
      });
    });

    it('does not render feature card component', () => {
      expect(findFeatureCards().length).toBe(0);
    });
    it('renders component with correct props', () => {
      expect(findSecretPushProtection().exists()).toBe(true);
      expect(findSecretPushProtection().props('feature')).toEqual(secretPushProtectionMock);
    });
  });

  describe('given gitlabCiPresent & gitlabCiHistoryPath props', () => {
    beforeEach(() => {
      createComponent({
        gitlabCiPresent: true,
        gitlabCiHistoryPath,
      });
    });

    it('should show configuration History Link', () => {
      expect(findSecurityViewHistoryLink().exists()).toBe(true);

      expect(findSecurityViewHistoryLink().attributes('href')).toBe('test/historyPath');
    });
  });

  describe('Vulnerability management', () => {
    const props = { securityTrainingEnabled: true };

    beforeEach(() => {
      createComponent({
        ...props,
      });
    });

    it('shows the tab', () => {
      expect(findVulnerabilityManagementTab().exists()).toBe(true);
    });

    it('renders TrainingProviderList component', () => {
      expect(findTrainingProviderList().props()).toMatchObject(props);
    });

    it('renders security training description', () => {
      expect(findVulnerabilityManagementTab().text()).toContain(i18n.securityTrainingDescription);
    });

    it('renders link to help docs', () => {
      const trainingLink = findVulnerabilityManagementTab().findComponent(GlLink);

      expect(trainingLink.text()).toBe('Learn more about vulnerability training');
      expect(trainingLink.attributes('href')).toBe(vulnerabilityTrainingDocsPath);
    });
  });
});
