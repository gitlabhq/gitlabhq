import { GlAlert, GlAttributeList } from '@gitlab/ui';
import { shallowMountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import { TEST_HOST } from 'helpers/test_constants';
import Step3 from '~/groups/settings/create_organization/components/steps/step_3.vue';
import BaseStep from '~/groups/settings/create_organization/components/steps/base_step.vue';
import { mockNewOrganization } from '../mock_data';

describe('ReconciliationStep3', () => {
  let wrapper;

  const [mockGroup] = mockNewOrganization.groups.nodes;
  const [mockOwner] = mockGroup.groupMembers.nodes;

  const groupWithOwners = (id, owners) => ({
    ...mockGroup,
    id,
    groupMembers: { ...mockGroup.groupMembers, nodes: owners },
  });

  const owner = (id, name) => ({
    ...mockOwner,
    id: `gid://gitlab/GroupMember/${id}`,
    user: { ...mockOwner.user, id: `gid://gitlab/User/${id}`, name },
  });

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Step3, {
      propsData: {
        organization: mockNewOrganization,
        ...props,
      },
      stubs: {
        BaseStep,
        GlAttributeList,
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAttributeListItems = () =>
    wrapper.findAllByTestId('gl-attribute-list-item').wrappers.map((item) => {
      const itemWrapper = extendedWrapper(item);

      return {
        label: trimText(itemWrapper.findByTestId('gl-attribute-list-item-label').text()),
        description: trimText(
          itemWrapper.findByTestId('gl-attribute-list-item-description').text(),
        ),
      };
    });
  const findAttributeListItemByLabel = (label) =>
    findAttributeListItems().find((item) => item.label === label);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders step title', () => {
      expect(findBaseStep().props('title')).toBe('Confirm your organization');
    });

    it('renders step description', () => {
      expect(
        wrapper
          .findByText(
            'After you confirm your organization structure, your data will be transferred to your organization.',
          )
          .exists(),
      ).toBe(true);
    });

    it('renders confirmation heading', () => {
      expect(wrapper.findByText('You are confirming:').exists()).toBe(true);
    });

    it('renders the organization attributes', () => {
      expect(findAttributeListItems()).toEqual([
        {
          label: 'Organization name',
          description: `${mockNewOrganization.name} Editable later from your Organization page`,
        },
        {
          label: 'URL',
          description: `${TEST_HOST}/o/${mockNewOrganization.path} Editable later from your Organization page`,
        },
        { label: 'Top-level groups', description: '1 top-level group' },
        { label: 'Organization administrators', description: mockOwner.user.name },
      ]);
    });
  });

  describe('top-level groups count', () => {
    it('renders the plural text when the organization has multiple groups', () => {
      createComponent({
        props: {
          organization: {
            ...mockNewOrganization,
            groups: {
              ...mockNewOrganization.groups,
              nodes: [mockGroup, { ...mockGroup, id: 'gid://gitlab/Group/2' }],
            },
          },
        },
      });

      expect(findAttributeListItemByLabel('Top-level groups').description).toBe(
        '2 top-level groups',
      );
    });
  });

  describe('organization administrators', () => {
    const sharedOwner = owner(1, 'Shared Owner');
    const otherSharedOwner = owner(2, 'Other Shared Owner');

    const createComponentWithGroups = (nodes) =>
      createComponent({
        props: {
          organization: {
            ...mockNewOrganization,
            groups: { ...mockNewOrganization.groups, nodes },
          },
        },
      });

    const findAdmins = () =>
      findAttributeListItemByLabel('Organization administrators').description;

    it('lists only owners the groups have in common', () => {
      createComponentWithGroups([
        groupWithOwners('gid://gitlab/Group/1', [sharedOwner, owner(3, 'Only In First')]),
        groupWithOwners('gid://gitlab/Group/2', [sharedOwner, owner(4, 'Only In Second')]),
      ]);

      expect(findAdmins()).toBe(sharedOwner.user.name);
    });

    it('lists every common owner, separated by commas', () => {
      createComponentWithGroups([
        groupWithOwners('gid://gitlab/Group/1', [sharedOwner, otherSharedOwner]),
        groupWithOwners('gid://gitlab/Group/2', [otherSharedOwner, sharedOwner]),
      ]);

      expect(findAdmins()).toBe(`${sharedOwner.user.name}, ${otherSharedOwner.user.name}`);
    });

    it('renders no administrators when the groups have no owners in common', () => {
      createComponentWithGroups([
        groupWithOwners('gid://gitlab/Group/1', [owner(3, 'Only In First')]),
        groupWithOwners('gid://gitlab/Group/2', [owner(4, 'Only In Second')]),
      ]);

      expect(findAdmins()).toBe('');
    });

    it('lists the single group owners when the organization has one group', () => {
      createComponentWithGroups([
        groupWithOwners('gid://gitlab/Group/1', [sharedOwner, otherSharedOwner]),
      ]);

      expect(findAdmins()).toBe(`${sharedOwner.user.name}, ${otherSharedOwner.user.name}`);
    });
  });

  describe('warning alert', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a non-dismissible alert', () => {
      expect(findAlert().props('dismissible')).toBe(false);
    });

    it('renders the actions that cannot be undone', () => {
      expect(trimText(findAlert().text())).toBe(
        'After confirmation, you cannot: Delete the organization Remove or add top-level groups. Contact support if you must make changes.',
      );
    });
  });
});
