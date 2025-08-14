import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import projects from 'test_fixtures/api/users/projects/get.json';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ListItemInactiveBadge from '~/vue_shared/components/resource_lists/list_item_inactive_badge.vue';

describe('ListItemInactiveBadge', () => {
  let wrapper;

  const [resource] = convertObjectPropsToCamelCase(projects, { deep: true });
  const defaultProps = {
    resource,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(ListItemInactiveBadge, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);

  describe.each`
    isSelfDeletionInProgress | markedForDeletionOn | archived | variant      | text
    ${true}                  | ${'2024-01-01'}     | ${true}  | ${'warning'} | ${'Deletion in progress'}
    ${true}                  | ${'2024-01-01'}     | ${false} | ${'warning'} | ${'Deletion in progress'}
    ${true}                  | ${null}             | ${true}  | ${'warning'} | ${'Deletion in progress'}
    ${true}                  | ${null}             | ${false} | ${'warning'} | ${'Deletion in progress'}
    ${false}                 | ${'2024-01-01'}     | ${true}  | ${'warning'} | ${'Pending deletion'}
    ${false}                 | ${'2024-01-01'}     | ${false} | ${'warning'} | ${'Pending deletion'}
    ${false}                 | ${null}             | ${true}  | ${'info'}    | ${'Archived'}
    ${false}                 | ${null}             | ${false} | ${false}     | ${false}
  `(
    'when isSelfDeletionInProgress=$isSelfDeletionInProgress, markedForDeletionOn=markedForDeletionOn, archived=$archived',
    ({ isSelfDeletionInProgress, markedForDeletionOn, archived, variant, text }) => {
      beforeEach(() => {
        createComponent({
          props: {
            resource: {
              ...resource,
              archived,
              markedForDeletionOn,
              isSelfDeletionInProgress,
            },
          },
        });
      });

      it('renders badge correctly', () => {
        expect(findGlBadge().exists() && findGlBadge().props('variant')).toBe(variant);
        expect(findGlBadge().exists() && findGlBadge().text()).toBe(text);
      });
    },
  );
});
