import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import { TYPE_EPIC, TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';

import ImportedBadge from '~/vue_shared/components/imported_badge.vue';

describe('ImportedBadge', () => {
  let wrapper;
  const defaultProps = {
    importableType: TYPE_ISSUE,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(ImportedBadge, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findBadgeTooltip = () => getBinding(findBadge().element, 'gl-tooltip');

  it('renders "Imported" badge', () => {
    createComponent();

    expect(findBadge().text()).toBe('Imported');
  });

  it.each`
    importableType        | tooltipText
    ${TYPE_EPIC}          | ${'This epic was imported from another instance.'}
    ${TYPE_ISSUE}         | ${'This issue was imported from another instance.'}
    ${TYPE_MERGE_REQUEST} | ${'This merge request was imported from another instance.'}
  `('renders tooltip for $importableType', ({ importableType, tooltipText }) => {
    createComponent({
      props: {
        importableType,
      },
    });

    expect(findBadgeTooltip().value).toBe(tooltipText);
  });
});
