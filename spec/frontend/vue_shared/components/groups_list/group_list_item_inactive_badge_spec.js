import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupListItemInactiveBadge from '~/vue_shared/components/groups_list/group_list_item_inactive_badge.vue';
import { groups } from 'jest/vue_shared/components/groups_list/mock_data';

describe('GroupListItemInactiveBadge', () => {
  let wrapper;

  const [group] = groups;

  const defaultProps = { group };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GroupListItemInactiveBadge, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);

  describe.each`
    markedForDeletionOn | variant      | text
    ${null}             | ${false}     | ${false}
    ${'2024-01-01'}     | ${'warning'} | ${'Pending deletion'}
  `(
    'when group.markedForDeletionOn is $markedForDeletionOn',
    ({ markedForDeletionOn, variant, text }) => {
      beforeEach(() => {
        createComponent({
          props: {
            group: {
              ...group,
              markedForDeletionOn,
            },
          },
        });
      });

      it('renders the badge correctly', () => {
        expect(findGlBadge().exists() && findGlBadge().props('variant')).toBe(variant);
        expect(findGlBadge().exists() && findGlBadge().text()).toBe(text);
      });
    },
  );
});
