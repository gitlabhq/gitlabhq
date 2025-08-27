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
    isSelfDeletionInProgress | markedForDeletion | archived | variant      | text
    ${true}                  | ${true}           | ${true}  | ${'warning'} | ${'Deletion in progress'}
    ${true}                  | ${true}           | ${false} | ${'warning'} | ${'Deletion in progress'}
    ${true}                  | ${false}          | ${true}  | ${'warning'} | ${'Deletion in progress'}
    ${true}                  | ${false}          | ${false} | ${'warning'} | ${'Deletion in progress'}
    ${false}                 | ${true}           | ${true}  | ${'warning'} | ${'Pending deletion'}
    ${false}                 | ${true}           | ${false} | ${'warning'} | ${'Pending deletion'}
    ${false}                 | ${false}          | ${true}  | ${'info'}    | ${'Archived'}
    ${false}                 | ${false}          | ${false} | ${false}     | ${false}
  `(
    'when isSelfDeletionInProgress=$isSelfDeletionInProgress, markedForDeletion=markedForDeletion, archived=$archived',
    ({ isSelfDeletionInProgress, markedForDeletion, archived, variant, text }) => {
      beforeEach(() => {
        createComponent({
          props: {
            resource: {
              ...resource,
              archived,
              markedForDeletion,
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
