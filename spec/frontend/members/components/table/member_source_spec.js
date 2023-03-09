import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import MemberSource from '~/members/components/table/member_source.vue';

describe('MemberSource', () => {
  let wrapper;

  const memberSource = {
    id: 102,
    fullName: 'Foo bar',
    webUrl: 'https://gitlab.com/groups/foo-bar',
  };

  const createdBy = {
    name: 'Administrator',
    webUrl: 'https://gitlab.com/root',
  };

  const createComponent = (propsData) => {
    wrapper = mountExtended(MemberSource, {
      propsData: {
        memberSource,
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const getTooltipDirective = (elementWrapper) => getBinding(elementWrapper.element, 'gl-tooltip');

  describe('direct member', () => {
    describe('when created by is available', () => {
      it('displays "Direct member by <user name>"', () => {
        createComponent({
          isDirectMember: true,
          createdBy,
        });

        expect(wrapper.text()).toBe('Direct member by Administrator');
        expect(wrapper.findByRole('link', { name: createdBy.name }).attributes('href')).toBe(
          createdBy.webUrl,
        );
      });
    });

    describe('when created by is not available', () => {
      it('displays "Direct member"', () => {
        createComponent({
          isDirectMember: true,
        });

        expect(wrapper.text()).toBe('Direct member');
      });
    });
  });

  describe('inherited member', () => {
    describe('when created by is available', () => {
      beforeEach(() => {
        createComponent({
          isDirectMember: false,
          createdBy,
        });
      });

      it('displays "<group name> by <user name>"', () => {
        expect(wrapper.text()).toBe('Foo bar by Administrator');
        expect(wrapper.findByRole('link', { name: memberSource.fullName }).attributes('href')).toBe(
          memberSource.webUrl,
        );
        expect(wrapper.findByRole('link', { name: createdBy.name }).attributes('href')).toBe(
          createdBy.webUrl,
        );
      });
    });

    describe('when created by is not available', () => {
      beforeEach(() => {
        createComponent({
          isDirectMember: false,
        });
      });

      it('displays a link to source group', () => {
        expect(wrapper.text()).toBe(memberSource.fullName);
        expect(wrapper.attributes('href')).toBe(memberSource.webUrl);
      });

      it('displays tooltip with "Inherited"', () => {
        const tooltipDirective = getTooltipDirective(wrapper);

        expect(tooltipDirective).not.toBeUndefined();
        expect(tooltipDirective.value).toBe('Inherited');
      });
    });
  });
});
