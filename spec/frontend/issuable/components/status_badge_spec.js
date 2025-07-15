import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatusBadge from '~/issuable/components/status_badge.vue';

describe('StatusBadge component', () => {
  let wrapper;

  const mountComponent = ({ props = {}, features = {} } = {}) => {
    wrapper = shallowMount(StatusBadge, {
      propsData: {
        ...props,
      },
      provide: {
        glFeatures: {
          showMergeRequestStatusDraft: false,
          ...features,
        },
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  describe.each`
    issuableType       | badgeText   | state       | badgeVariant | badgeIcon
    ${'merge_request'} | ${'Open'}   | ${'opened'} | ${'success'} | ${'merge-request'}
    ${'merge_request'} | ${'Closed'} | ${'closed'} | ${'danger'}  | ${'merge-request-close'}
    ${'merge_request'} | ${'Merged'} | ${'merged'} | ${'info'}    | ${'merge'}
    ${'issue'}         | ${'Open'}   | ${'opened'} | ${'success'} | ${'issue-open-m'}
    ${'issue'}         | ${'Closed'} | ${'closed'} | ${'info'}    | ${'issue-close'}
    ${'epic'}          | ${'Open'}   | ${'opened'} | ${'success'} | ${'issue-open-m'}
    ${'epic'}          | ${'Closed'} | ${'closed'} | ${'info'}    | ${'issue-close'}
  `(
    'when issuableType=$issuableType and state=$state',
    ({ issuableType, badgeText, state, badgeVariant, badgeIcon }) => {
      beforeEach(() => {
        mountComponent({ props: { state, issuableType } });
      });

      it(`renders badge with text '${badgeText}'`, () => {
        expect(findBadge().text()).toBe(badgeText);
      });

      it(`sets badge variant as '${badgeVariant}`, () => {
        expect(findBadge().props('variant')).toBe(badgeVariant);
      });

      it(`sets badge icon as '${badgeIcon}'`, () => {
        expect(findBadge().props('icon')).toBe(badgeIcon);
      });
    },
  );

  it('renders Draft badge when MR is open and is a draft', () => {
    mountComponent({
      props: {
        issuableType: 'merge_request',
        state: 'opened',
        isDraft: true,
      },
      features: {
        showMergeRequestStatusDraft: true,
      },
    });

    expect(findBadge().props('variant')).toBe('warning');
    expect(findBadge().text()).toBe('Draft');
  });
});
