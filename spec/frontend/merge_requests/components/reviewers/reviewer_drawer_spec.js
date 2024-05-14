import { shallowMount } from '@vue/test-utils';
import { GlDrawer } from '@gitlab/ui';
import ReviewerDrawer from '~/merge_requests/components/reviewers/reviewer_drawer.vue';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

jest.mock('~/lib/utils/dom_utils', () => ({ getContentWrapperHeight: jest.fn() }));

let wrapper;

function createComponent(propsData = {}) {
  wrapper = shallowMount(ReviewerDrawer, {
    propsData,
    provide: {
      projectPath: 'gitlab-org/gitlab',
      issuableId: '1',
      issuableIid: '1',
      multipleApprovalRulesAvailable: false,
    },
  });
}

const findDrawer = () => wrapper.findComponent(GlDrawer);

describe('Reviewer drawer component', () => {
  it('renders the drawer', () => {
    createComponent({ open: true });

    expect(findDrawer().exists()).toBe(true);
    expect(findDrawer().props()).toMatchObject(
      expect.objectContaining({ open: true, zIndex: 252 }),
    );
  });

  describe('heeader height', () => {
    it.each`
      height   | open
      ${'0'}   | ${false}
      ${'200'} | ${true}
    `('sets height header-height prop to $height when open is $open', ({ height, open }) => {
      getContentWrapperHeight.mockReturnValue('200');

      createComponent({ open });

      expect(findDrawer().props('headerHeight')).toBe(height);
    });
  });
});
