import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import { RUNNER_TAG_BADGE_VARIANT } from '~/ci/runner/constants';
import RunnerTag from '~/ci/runner/components/runner_tag.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

const mockTag = 'tag1';

describe('RunnerTag', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const getTooltipValue = () => getBinding(findBadge().element, 'gl-tooltip').value;

  const setDimensions = ({ scrollWidth, offsetWidth }) => {
    const content = findBadge().element.querySelector('span');

    jest.spyOn(content, 'scrollWidth', 'get').mockReturnValue(scrollWidth);
    jest.spyOn(content, 'offsetWidth', 'get').mockReturnValue(offsetWidth);

    // Mock trigger resize
    getBinding(content, 'gl-resize-observer').value({ target: content });
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerTag, {
      propsData: {
        tag: mockTag,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
        GlResizeObserver: createMockDirective('gl-resize-observer'),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Displays tag text', () => {
    expect(wrapper.text()).toBe(mockTag);
  });

  it('Displays tags with correct style', () => {
    expect(findBadge().props()).toMatchObject({
      variant: RUNNER_TAG_BADGE_VARIANT,
    });
  });

  it.each`
    case                    | scrollWidth | offsetWidth | expectedTooltip
    ${'overflowing'}        | ${110}      | ${100}      | ${mockTag}
    ${'not overflowing'}    | ${90}       | ${100}      | ${''}
    ${'almost overflowing'} | ${100}      | ${100}      | ${''}
  `(
    'Sets "$expectedTooltip" as tooltip when $case',
    async ({ scrollWidth, offsetWidth, expectedTooltip }) => {
      setDimensions({ scrollWidth, offsetWidth });
      await nextTick();

      expect(getTooltipValue()).toBe(expectedTooltip);
    },
  );
});
