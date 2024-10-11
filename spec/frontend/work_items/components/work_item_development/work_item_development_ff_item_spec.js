import { GlLink, GlIcon, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { workItemDevelopmentFeatureFlagNodes } from 'jest/work_items/mock_data';
import WorkItemDevelopmentFfItem from '~/work_items/components/work_item_development/work_item_development_ff_item.vue';

jest.mock('~/alert');

describe('WorkItemDevelopmentFfItem', () => {
  let wrapper;

  const enabledFeatureFlag = workItemDevelopmentFeatureFlagNodes[0];
  const disabledFeatureFlag = workItemDevelopmentFeatureFlagNodes[1];

  const createComponent = ({ featureFlag = enabledFeatureFlag }) => {
    wrapper = shallowMount(WorkItemDevelopmentFfItem, {
      propsData: {
        itemContent: featureFlag,
      },
    });
  };

  const findFlagIcon = () => wrapper.findComponent(GlIcon);
  const findFlagLink = () => wrapper.findComponent(GlLink);
  const findFlagTooltip = () => wrapper.findComponent(GlTooltip);

  describe('feature flag status icon', () => {
    it.each`
      state         | icon                       | featureFlag            | iconClass
      ${'Enabled'}  | ${'feature-flag'}          | ${enabledFeatureFlag}  | ${'gl-text-blue-500'}
      ${'Disabled'} | ${'feature-flag-disabled'} | ${disabledFeatureFlag} | ${'gl-text-gray-500'}
    `(
      'renders icon "$icon" when the state of the feature flag is "$state"',
      ({ icon, iconClass, featureFlag }) => {
        createComponent({ featureFlag });

        expect(findFlagIcon().props('name')).toBe(icon);
        expect(findFlagIcon().attributes('class')).toBe(iconClass);
      },
    );
  });

  describe('feature flag link and name', () => {
    it('should render the flag path and name', () => {
      createComponent({ featureFlag: enabledFeatureFlag });

      expect(findFlagLink().attributes('href')).toBe(enabledFeatureFlag.path);
      expect(findFlagLink().attributes('href')).toContain(`/edit`);

      expect(findFlagLink().text()).toBe(enabledFeatureFlag.name);
    });
  });

  describe('eature flag tooltip', () => {
    it('should render the tooltip with flag name, reference and "Enabled" copy if active', () => {
      createComponent({ featureFlag: enabledFeatureFlag });

      expect(findFlagTooltip().exists()).toBe(true);
      expect(findFlagTooltip().text()).toContain(
        `${enabledFeatureFlag.name} ${enabledFeatureFlag.reference} Enabled`,
      );
    });

    it('should render the tooltip with flag name, reference and "Disabled" copy if not active', () => {
      createComponent({ featureFlag: disabledFeatureFlag });

      expect(findFlagTooltip().exists()).toBe(true);
      expect(findFlagTooltip().text()).toContain(
        `${disabledFeatureFlag.name} ${disabledFeatureFlag.reference} Disabled`,
      );
    });
  });
});
