import { GlIcon, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';

import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
  VISIBILITY_LEVELS_STRING_TO_INTEGER,
  GROUP_VISIBILITY_LEVEL_DESCRIPTIONS,
} from '~/visibility_level/constants';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('VisibilityLevelRadioButtons', () => {
  let wrapper;

  const defaultPropsData = {
    checked: VISIBILITY_LEVEL_PRIVATE_INTEGER,
    visibilityLevels: Object.values(VISIBILITY_LEVELS_STRING_TO_INTEGER),
    visibilityLevelDescriptions: GROUP_VISIBILITY_LEVEL_DESCRIPTIONS,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(VisibilityLevelRadioButtons, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  it('renders radio group with `checked` prop correctly set', () => {
    createComponent();

    expect(findRadioGroup().vm.$attrs.checked).toBe(defaultPropsData.checked);
  });

  describe('when radio group emits `input` event', () => {
    beforeEach(() => {
      createComponent();
      findRadioGroup().vm.$emit('input', VISIBILITY_LEVEL_PUBLIC_INTEGER);
    });

    it('emits `input` event', () => {
      expect(wrapper.emitted('input')).toEqual([[VISIBILITY_LEVEL_PUBLIC_INTEGER]]);
    });
  });

  it('renders visibility level radio buttons with label, description, and icon', () => {
    createComponent();

    const radioButtons = wrapper.findAllComponents(GlFormRadio);

    expect(radioButtons.at(0).text()).toMatchInterpolatedText(
      'Private The group and its projects can only be viewed by members.',
    );
    expect(radioButtons.at(0).findComponent(GlIcon).props('name')).toBe('lock');

    expect(radioButtons.at(1).text()).toMatchInterpolatedText(
      'Internal The group and any internal projects can be viewed by any logged in user except external users.',
    );
    expect(radioButtons.at(1).findComponent(GlIcon).props('name')).toBe('shield');

    expect(radioButtons.at(2).text()).toMatchInterpolatedText(
      'Public The group and any public projects can be viewed without any authentication.',
    );
    expect(radioButtons.at(2).findComponent(GlIcon).props('name')).toBe('earth');
  });
});
