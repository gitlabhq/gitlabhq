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
    issuableType       | badgeText   | initialState | badgeVariant | badgeIcon
    ${'merge_request'} | ${'Open'}   | ${'opened'}  | ${'success'} | ${'merge-request-open'}
    ${'merge_request'} | ${'Closed'} | ${'closed'}  | ${'danger'}  | ${'merge-request-close'}
    ${'merge_request'} | ${'Merged'} | ${'merged'}  | ${'info'}    | ${'merge'}
    ${'issue'}         | ${'Open'}   | ${'opened'}  | ${'success'} | ${'issues'}
    ${'issue'}         | ${'Closed'} | ${'closed'}  | ${'info'}    | ${'issue-closed'}
    ${'epic'}          | ${'Open'}   | ${'opened'}  | ${'success'} | ${'epic'}
    ${'epic'}          | ${'Closed'} | ${'closed'}  | ${'info'}    | ${'epic-closed'}
  `(
    'with issuableType set to "$issuableType" and state set to "$initialState"',
    ({ issuableType, badgeText, initialState, badgeVariant, badgeIcon }) => {
      beforeEach(() => {
        factory({
          initialState,
          issuableType,
        });
      });

      it(`renders badge with text '${badgeText}'`, () => {
        expect(findBadge().text()).toBe(badgeText);
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
