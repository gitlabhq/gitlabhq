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
    markedForDeletion | isSelfDeletionInProgress | variant      | text
    ${false}          | ${false}                 | ${false}     | ${false}
    ${true}           | ${false}                 | ${'warning'} | ${'Pending deletion'}
    ${false}          | ${true}                  | ${'warning'} | ${'Deletion in progress'}
  `(
    'when group.markedForDeletion is $markedForDeletion and group.isSelfDeletionInProgress is $isSelfDeletionInProgress',
    ({ markedForDeletion, isSelfDeletionInProgress, variant, text }) => {
      beforeEach(() => {
        createComponent({
          props: {
            group: {
              ...group,
              markedForDeletion,
              isSelfDeletionInProgress,
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
