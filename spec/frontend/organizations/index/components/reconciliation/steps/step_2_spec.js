import { GlCard } from '@gitlab/ui';
import { nextTick } from 'vue';
import Draggable from '~/lib/utils/vue3compat/draggable_compat.vue';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import Step2 from '~/organizations/index/components/reconciliation/steps/step_2.vue';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';
import OrganizationCard from '~/organizations/index/components/reconciliation/organization_card.vue';
import OrganizationGroupCard from '~/organizations/index/components/reconciliation/organization_group_card.vue';
import {
  mockOrganizations,
  organizationWithGroupsIndex,
  organizationWithGroups,
  organizationWithoutGroupsIndex,
  organizationWithoutGroups,
} from '../mock_data';

describe('ReconciliationStep2', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(Step2, {
      propsData: {
        organizations: mockOrganizations,
        ...props,
      },
      stubs: {
        Draggable: stubComponent(Draggable),
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);
  const findAllCards = () => wrapper.findAllComponents(GlCard);
  const findCardAt = (index) => extendedWrapper(findAllCards().at(index));
  const findAllOrganizationCards = () => wrapper.findAllComponents(OrganizationCard);
  const findAllGroupCards = (organizationCard) =>
    organizationCard.findAllComponents(OrganizationGroupCard);

  it('renders step title', () => {
    createComponent();

    expect(findBaseStep().props('title')).toBe('Assign top-level groups');
  });

  it('renders step description', () => {
    createComponent();

    expect(findBaseStep().text()).toContain(
      'Drag groups between Organizations to set up your structure. Most companies only need one.',
    );
  });

  it('renders an organization card for each organization', () => {
    createComponent();

    expect(findAllOrganizationCards()).toHaveLength(mockOrganizations.length);
  });

  it('passes organization prop to organization card', () => {
    createComponent();

    expect(findAllOrganizationCards().at(0).props('organization')).toEqual(mockOrganizations[0]);
  });

  describe('when organization has groups', () => {
    const groups = organizationWithGroups.groups.nodes;

    it('renders group cards', () => {
      createComponent();

      const card = findCardAt(organizationWithGroupsIndex);
      const groupCards = findAllGroupCards(card);

      expect(groupCards).toHaveLength(groups.length);
    });

    it('passes group prop to organization group card', () => {
      createComponent();

      const card = findCardAt(organizationWithGroupsIndex);
      expect(findAllGroupCards(card).at(0).props('group')).toEqual(groups[0]);
    });
  });

  describe('drag and drop', () => {
    const findAllDraggableComponents = () => wrapper.findAllComponents(Draggable);

    it('renders drag and drop group for each organization', () => {
      createComponent();

      const draggableComponents = findAllDraggableComponents();

      expect(draggableComponents).toHaveLength(mockOrganizations.length);
      expect(
        draggableComponents.wrappers.every(
          (draggable) => draggable.attributes('group') === 'organizationGroups',
        ),
      ).toBe(true);
    });

    describe('when group is moved between organizations', () => {
      it('emits update event once with updated organization structure', async () => {
        createComponent();

        const draggableComponents = findAllDraggableComponents();

        const draggableWithGroups = draggableComponents.at(organizationWithGroupsIndex);
        const draggableWithoutGroups = draggableComponents.at(organizationWithoutGroupsIndex);
        const groupToMoveIndex = 0;
        const groupToMove = organizationWithGroups.groups.nodes[groupToMoveIndex];

        draggableWithGroups.vm.$emit(
          'input',
          organizationWithGroups.groups.nodes.toSpliced(groupToMoveIndex, 1),
        );
        draggableWithoutGroups.vm.$emit('input', [groupToMove]);
        draggableWithoutGroups.vm.$emit('end');

        await nextTick();

        const expectedOrganizations = mockOrganizations
          .toSpliced(organizationWithGroupsIndex, 1, {
            ...organizationWithGroups,
            groups: {
              ...organizationWithGroups.groups,
              nodes: organizationWithGroups.groups.nodes.toSpliced(groupToMoveIndex, 1),
            },
          })
          .toSpliced(organizationWithoutGroupsIndex, 1, {
            ...organizationWithoutGroups,
            groups: {
              ...organizationWithoutGroups.groups,
              nodes: [groupToMove],
            },
          });

        expect(wrapper.emitted('update')).toEqual([[expectedOrganizations]]);
      });
    });
  });
});
