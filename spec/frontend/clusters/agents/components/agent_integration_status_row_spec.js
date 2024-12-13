import { GlLink, GlIcon, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AgentIntegrationStatusRow from '~/clusters/agents/components/agent_integration_status_row.vue';

const defaultProps = {
  text: 'Default integration status',
};

describe('IntegrationStatus', () => {
  let wrapper;

  const createWrapper = ({ props = {}, glFeatures = {} } = {}) => {
    wrapper = shallowMount(AgentIntegrationStatusRow, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        glFeatures,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('icon', () => {
    const icon = 'status-success';
    const iconClass = 'gl-text-success';
    it.each`
      props                  | iconName         | iconClassName
      ${{ icon, iconClass }} | ${icon}          | ${iconClass}
      ${{ icon }}            | ${icon}          | ${'text-info'}
      ${{ iconClass }}       | ${'information'} | ${iconClass}
      ${null}                | ${'information'} | ${'text-info'}
    `('displays correct icon when props are $props', ({ props, iconName, iconClassName }) => {
      createWrapper({ props });

      expect(findIcon().props('name')).toBe(iconName);
      expect(findIcon().attributes('class')).toContain(iconClassName);
    });
  });

  describe('helpUrl', () => {
    it('displays a link with the correct help url when provided in props', () => {
      const props = {
        helpUrl: 'help-page-path',
      };
      createWrapper({ props });

      expect(findLink().attributes('href')).toBe(props.helpUrl);
      expect(findLink().text()).toBe(defaultProps.text);
    });

    it("displays the text without a link when it's not provided", () => {
      createWrapper();

      expect(findLink().exists()).toBe(false);
      expect(wrapper.text()).toBe(defaultProps.text);
    });
  });

  describe('badge', () => {
    it('does not display premium feature badge when featureName is not provided', () => {
      createWrapper();

      expect(findBadge().exists()).toBe(false);
    });

    it('does not display premium feature badge when featureName is provided and is available for the project', () => {
      const props = { featureName: 'feature' };
      const glFeatures = { feature: true };
      createWrapper({ props, glFeatures });

      expect(findBadge().exists()).toBe(false);
    });

    it('displays premium feature badge when featureName is provided and is not available for the project', () => {
      const props = { featureName: 'feature' };
      const glFeatures = { feature: false };
      createWrapper({ props, glFeatures });

      expect(findBadge().props()).toMatchObject({
        icon: 'license',
        variant: 'tier',
      });
      expect(findBadge().text()).toBe(wrapper.vm.$options.i18n.premiumTitle);
    });
  });
});
