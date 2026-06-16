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
  mockGroup,
  defaultOrgWithGroups,
  defaultOrgWithoutGroups,
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
        initialDefaultOrgGroupIds: [],
        ...props,
      },
      stubs: {
        Draggable: stubComponent(Draggable, { props: ['group', 'fallbackClass'] }),
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);
  const findAllCards = () => wrapper.findAllComponents(GlCard);
  const findCardAt = (index) => extendedWrapper(findAllCards().at(index));
  const findAllOrganizationCards = () => wrapper.findAllComponents(OrganizationCard);
  const findAllGroupCards = (organizationCard) =>
    organizationCard.findAllComponents(OrganizationGroupCard);
  const findDropZone = (cardIndex) => findCardAt(cardIndex).findByTestId('organization-dropzone');

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
    const findDraggableWithGroups = () =>
      findAllDraggableComponents().at(organizationWithGroupsIndex);
    const findDraggableWithoutGroups = () =>
      findAllDraggableComponents().at(organizationWithoutGroupsIndex);

    it('renders a draggable for each organization', () => {
      createComponent();

      expect(findAllDraggableComponents()).toHaveLength(mockOrganizations.length);
    });

    it('passes fallbackClass prop to each draggable', () => {
      createComponent();

      findAllDraggableComponents().wrappers.forEach((draggable) => {
        expect(draggable.props('fallbackClass')).toBe(
          'organizations-reconciliation-draggable-fallback',
        );
      });
    });

    describe('when component is destroyed', () => {
      const FALLBACK_CSS_CLASS = 'organizations-reconciliation-draggable-fallback';

      it('removes lingering fallback element from the DOM', () => {
        createComponent();

        const fallbackEl = document.createElement('div');
        fallbackEl.classList.add(FALLBACK_CSS_CLASS);
        document.body.appendChild(fallbackEl);

        wrapper.destroy();

        expect(document.querySelector(`.${FALLBACK_CSS_CLASS}`)).toBe(null);
      });

      it('does not throw when no fallback element is present', () => {
        createComponent();

        expect(() => wrapper.destroy()).not.toThrow();
      });
    });

    describe('when item is chosen', () => {
      const DRAGGING_CSS_CLASS = 'organizations-reconciliation-draggable-dragging';

      beforeEach(() => {
        createComponent();

        findDraggableWithGroups().vm.$emit('choose');
      });

      it('adds organizations-reconciliation-draggable-dragging CSS class to body', () => {
        expect(document.body.classList.contains(DRAGGING_CSS_CLASS)).toBe(true);
      });

      describe('when item is unchosen', () => {
        it('removes organizations-reconciliation-draggable-dragging CSS class from body', () => {
          findDraggableWithGroups().vm.$emit('unchoose');

          expect(document.body.classList.contains(DRAGGING_CSS_CLASS)).toBe(false);
        });
      });

      describe('when component is destroyed', () => {
        it('removes organizations-reconciliation-draggable-dragging CSS class from body', () => {
          wrapper.destroy();

          expect(document.body.classList.contains(DRAGGING_CSS_CLASS)).toBe(false);
        });
      });
    });

    describe('when group is moved between organizations', () => {
      it('emits update event once with updated organization structure', async () => {
        createComponent();

        const draggableWithGroups = findDraggableWithGroups();
        const draggableWithoutGroups = findDraggableWithoutGroups();
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

    describe('default organization drop zone', () => {
      const DEFAULT_ORG_INDEX = 0;
      const OTHER_ORG_INDEX = 1;

      const startDragFromOrg = async (orgIndex) => {
        findAllDraggableComponents().at(orgIndex).vm.$emit('start', { oldIndex: 0 });
        await nextTick();
      };

      describe('when all initial groups are still in the default organization', () => {
        beforeEach(() => {
          createComponent({
            props: {
              organizations: [defaultOrgWithGroups, organizationWithoutGroups],
              initialDefaultOrgGroupIds: [mockGroup.id],
            },
          });
        });

        it('hides the default organization drop zone', () => {
          expect(findDropZone(DEFAULT_ORG_INDEX).exists()).toBe(false);
        });

        it('always shows the non default organization drop zone', () => {
          expect(findDropZone(OTHER_ORG_INDEX).exists()).toBe(true);
        });
      });

      describe('when a group has been removed from the default organization', () => {
        beforeEach(() => {
          createComponent({
            props: {
              organizations: [defaultOrgWithoutGroups, organizationWithGroups],
              initialDefaultOrgGroupIds: [mockGroup.id],
            },
          });
        });

        it('shows the drop zone', () => {
          expect(findDropZone(DEFAULT_ORG_INDEX).exists()).toBe(true);
        });
      });

      describe('when dragging a group that was originally in the default organization', () => {
        beforeEach(async () => {
          createComponent({
            props: {
              organizations: [defaultOrgWithoutGroups, organizationWithGroups],
              initialDefaultOrgGroupIds: [mockGroup.id],
            },
          });
          await startDragFromOrg(OTHER_ORG_INDEX);
        });

        it('shows the drop zone', () => {
          expect(findDropZone(DEFAULT_ORG_INDEX).exists()).toBe(true);
        });

        it('sets the default organization group `put` to true', () => {
          const defaultOrgDraggable = findAllDraggableComponents().at(DEFAULT_ORG_INDEX);
          const group = defaultOrgDraggable.props('group');

          expect(group.put()).toBe(true);
        });
      });

      describe('when dragging a group that was not originally in the default organization', () => {
        beforeEach(async () => {
          createComponent({
            props: {
              organizations: [defaultOrgWithoutGroups, organizationWithGroups],
              initialDefaultOrgGroupIds: [],
            },
          });
          await startDragFromOrg(OTHER_ORG_INDEX);
        });

        it('hides the drop zone', () => {
          expect(findDropZone(DEFAULT_ORG_INDEX).exists()).toBe(false);
        });

        it('sets the default organization group `put` to false', () => {
          const defaultOrgDraggable = findAllDraggableComponents().at(DEFAULT_ORG_INDEX);
          const group = defaultOrgDraggable.props('group');

          expect(group.put()).toBe(false);
        });
      });
    });
  });
});
