import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VisibilityIcon from '~/vue_shared/components/visibility_icon.vue';
import {
  GROUP_VISIBILITY_TYPE,
  PROJECT_VISIBILITY_TYPE,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
  VISIBILITY_TYPE_ICON,
} from '~/visibility_level/constants';

describe('Visibility icon', () => {
  let glTooltipDirectiveMock;
  let wrapper;

  const createComponent = (props = {}) => {
    glTooltipDirectiveMock = jest.fn();

    wrapper = shallowMountExtended(VisibilityIcon, {
      directives: {
        GlTooltip: glTooltipDirectiveMock,
      },
      propsData: {
        ...props,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);

  describe('visibilityTooltip', () => {
    describe('if item represents group', () => {
      it.each`
        visibilityLevel                     | visibilityTooltip                                          | visibilityIcon                                            | tooltipPlacement
        ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${GROUP_VISIBILITY_TYPE[VISIBILITY_LEVEL_PUBLIC_STRING]}   | ${VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PUBLIC_STRING]}   | ${'top'}
        ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${GROUP_VISIBILITY_TYPE[VISIBILITY_LEVEL_INTERNAL_STRING]} | ${VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_INTERNAL_STRING]} | ${'bottom'}
        ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${GROUP_VISIBILITY_TYPE[VISIBILITY_LEVEL_PRIVATE_STRING]}  | ${VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PRIVATE_STRING]}  | ${'right'}
      `(
        'should return corresponding text when visibility level is $visibilityLevel',
        ({ visibilityLevel, visibilityTooltip, visibilityIcon, tooltipPlacement }) => {
          createComponent({ isGroup: true, visibilityLevel, tooltipPlacement });

          expect(findIcon().attributes()).toMatchObject({
            arialabel: visibilityTooltip,
            name: visibilityIcon,
            title: visibilityTooltip,
          });

          expect(glTooltipDirectiveMock.mock.calls[0][1].value).toEqual({
            placement: tooltipPlacement,
          });
        },
      );
    });

    describe('if item represents project', () => {
      it.each`
        visibilityLevel                     | visibilityTooltip                                            | visibilityIcon                                            | tooltipPlacement
        ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${PROJECT_VISIBILITY_TYPE[VISIBILITY_LEVEL_PUBLIC_STRING]}   | ${VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PUBLIC_STRING]}   | ${'top'}
        ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${PROJECT_VISIBILITY_TYPE[VISIBILITY_LEVEL_INTERNAL_STRING]} | ${VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_INTERNAL_STRING]} | ${'bottom'}
        ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${PROJECT_VISIBILITY_TYPE[VISIBILITY_LEVEL_PRIVATE_STRING]}  | ${VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PRIVATE_STRING]}  | ${'left'}
      `(
        'should return corresponding text when visibility level is $visibilityLevel',
        ({ visibilityLevel, visibilityTooltip, visibilityIcon, tooltipPlacement }) => {
          createComponent({ visibilityLevel, tooltipPlacement });

          expect(findIcon().attributes()).toMatchObject({
            arialabel: visibilityTooltip,
            name: visibilityIcon,
            title: visibilityTooltip,
          });

          expect(glTooltipDirectiveMock.mock.calls[0][1].value).toEqual({
            placement: tooltipPlacement,
          });
        },
      );
    });
  });
});
