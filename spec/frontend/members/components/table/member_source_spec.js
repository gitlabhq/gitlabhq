import { mount, createWrapper } from '@vue/test-utils';
import { getByText as getByTextHelper } from '@testing-library/dom';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import MemberSource from '~/members/components/table/member_source.vue';

describe('MemberSource', () => {
  let wrapper;

  const createComponent = propsData => {
    wrapper = mount(MemberSource, {
      propsData: {
        memberSource: {
          id: 102,
          name: 'Foo bar',
          webUrl: 'https://gitlab.com/groups/foo-bar',
        },
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  const getTooltipDirective = elementWrapper => getBinding(elementWrapper.element, 'gl-tooltip');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('direct member', () => {
    it('displays "Direct member"', () => {
      createComponent({
        isDirectMember: true,
      });

      expect(getByText('Direct member').exists()).toBe(true);
    });
  });

  describe('inherited member', () => {
    let sourceGroupLink;

    beforeEach(() => {
      createComponent({
        isDirectMember: false,
      });

      sourceGroupLink = getByText('Foo bar');
    });

    it('displays a link to source group', () => {
      createComponent({
        isDirectMember: false,
      });

      expect(sourceGroupLink.exists()).toBe(true);
      expect(sourceGroupLink.attributes('href')).toBe('https://gitlab.com/groups/foo-bar');
    });

    it('displays tooltip with "Inherited"', () => {
      const tooltipDirective = getTooltipDirective(sourceGroupLink);

      expect(tooltipDirective).not.toBeUndefined();
      expect(sourceGroupLink.attributes('title')).toBe('Inherited');
    });
  });
});
