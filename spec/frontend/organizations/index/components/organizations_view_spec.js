import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { organizations } from '~/organizations/mock_data';
import OrganizationsView from '~/organizations/index/components/organizations_view.vue';
import OrganizationsList from '~/organizations/index/components/organizations_list.vue';
import { MOCK_NEW_ORG_URL, MOCK_ORG_EMPTY_STATE_SVG } from '../mock_data';

describe('OrganizationsView', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(OrganizationsView, {
      propsData: {
        ...props,
      },
      provide: {
        newOrganizationUrl: MOCK_NEW_ORG_URL,
        organizationsEmptyStateSvgPath: MOCK_ORG_EMPTY_STATE_SVG,
      },
    });
  };

  const findGlLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findOrganizationsList = () => wrapper.findComponent(OrganizationsList);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe.each`
    description                                    | loading  | orgsData         | emptyStateSvg               | emptyStateUrl
    ${'when loading'}                              | ${true}  | ${[]}            | ${false}                    | ${false}
    ${'when not loading and has organizations'}    | ${false} | ${organizations} | ${false}                    | ${false}
    ${'when not loading and has no organizations'} | ${false} | ${[]}            | ${MOCK_ORG_EMPTY_STATE_SVG} | ${MOCK_NEW_ORG_URL}
  `('$description', ({ loading, orgsData, emptyStateSvg, emptyStateUrl }) => {
    beforeEach(() => {
      createComponent({ loading, organizations: { nodes: orgsData, pageInfo: {} } });
    });

    it(`does ${loading ? '' : 'not '}render loading icon`, () => {
      expect(findGlLoading().exists()).toBe(loading);
    });

    it(`does ${orgsData.length ? '' : 'not '}render organizations list`, () => {
      expect(findOrganizationsList().exists()).toBe(Boolean(orgsData.length));
    });

    it(`does ${emptyStateSvg ? '' : 'not '}render empty state with SVG`, () => {
      expect(findGlEmptyState().exists() && findGlEmptyState().attributes('svgpath')).toBe(
        emptyStateSvg,
      );
    });

    it(`does ${emptyStateUrl ? '' : 'not '}render empty state with URL`, () => {
      expect(
        findGlEmptyState().exists() && findGlEmptyState().attributes('primarybuttonlink'),
      ).toBe(emptyStateUrl);
    });
  });

  describe('when `OrganizationsList` emits `next` event', () => {
    const endCursor = 'mockEndCursor';

    beforeEach(() => {
      createComponent({ loading: false, organizations: { nodes: organizations, pageInfo: {} } });
      findOrganizationsList().vm.$emit('next', endCursor);
    });

    it('emits `next` event', () => {
      expect(wrapper.emitted('next')).toEqual([[endCursor]]);
    });
  });

  describe('when `OrganizationsList` emits `prev` event', () => {
    const startCursor = 'mockStartCursor';

    beforeEach(() => {
      createComponent({ loading: false, organizations: { nodes: organizations, pageInfo: {} } });
      findOrganizationsList().vm.$emit('prev', startCursor);
    });

    it('emits `next` event', () => {
      expect(wrapper.emitted('prev')).toEqual([[startCursor]]);
    });
  });
});
