import { GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatusBox from '~/issuable/components/status_box.vue';

let wrapper;

function factory(propsData) {
  wrapper = shallowMount(StatusBox, { propsData, stubs: { GlBadge } });
}

describe('Merge request status box component', () => {
  const findBadge = () => wrapper.findComponent(GlBadge);

  describe.each`
    issuableType       | badgeText   | initialState | badgeClass                        | badgeVariant | badgeIcon
    ${'merge_request'} | ${'Open'}   | ${'opened'}  | ${'issuable-status-badge-open'}   | ${'success'} | ${'merge-request-open'}
    ${'merge_request'} | ${'Closed'} | ${'closed'}  | ${'issuable-status-badge-closed'} | ${'danger'}  | ${'merge-request-close'}
    ${'merge_request'} | ${'Merged'} | ${'merged'}  | ${'issuable-status-badge-merged'} | ${'info'}    | ${'merge'}
    ${'issue'}         | ${'Open'}   | ${'opened'}  | ${'issuable-status-badge-open'}   | ${'success'} | ${'issues'}
    ${'issue'}         | ${'Closed'} | ${'closed'}  | ${'issuable-status-badge-closed'} | ${'info'}    | ${'issue-closed'}
  `(
    'with issuableType set to "$issuableType" and state set to "$initialState"',
    ({ issuableType, badgeText, initialState, badgeClass, badgeVariant, badgeIcon }) => {
      beforeEach(() => {
        factory({
          initialState,
          issuableType,
        });
      });

      it(`renders badge with text '${badgeText}'`, () => {
        expect(findBadge().text()).toBe(badgeText);
      });

      it(`sets badge css class as '${badgeClass}'`, () => {
        expect(findBadge().classes()).toContain(badgeClass);
      });

      it(`sets badge variant as '${badgeVariant}`, () => {
        expect(findBadge().props('variant')).toBe(badgeVariant);
      });

      it(`sets badge icon as '${badgeIcon}'`, () => {
        expect(findBadge().findComponent(GlIcon).props('name')).toBe(badgeIcon);
      });
    },
  );
});
