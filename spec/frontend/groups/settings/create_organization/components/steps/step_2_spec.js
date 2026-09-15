import { GlCard } from '@gitlab/ui';
import { nextTick } from 'vue';
import Draggable from '~/lib/utils/vue3compat/draggable_compat.vue';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import Step2 from '~/groups/settings/create_organization/components/steps/step_2.vue';
import BaseStep from '~/groups/settings/create_organization/components/steps/base_step.vue';
import OrganizationCard from '~/groups/settings/create_organization/components/organization_card.vue';
import OrganizationGroupCard from '~/groups/settings/create_organization/components/organization_group_card.vue';
import { mockOrganizations, mockNewOrganization, mockDefaultOrganization } from '../mock_data';

describe('ReconciliationStep2', () => {
  let wrapper;

  const defaultOrgGroupIds = mockDefaultOrganization.groups.nodes.map((group) => group.id);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(Step2, {
      propsData: {
        organizations: mockOrganizations,
        initialDefaultOrgGroupIds: [],
        ...props,
      },
      stubs: {
        Draggable: stubComponent(Draggable, {
          props: ['group', 'filter', 'fallbackClass', 'move'],
        }),
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

  describe('step description', () => {
    it('renders the singular description when the default organization initially had one group', () => {
      createComponent({ props: { initialDefaultOrgGroupIds: defaultOrgGroupIds } });

      expect(findBaseStep().text()).toContain(
        'You have 1 other top-level group. Drag unassigned groups to your organization, or leave the structure as is. Unassigned groups will not be included in the organization.',
      );
    });

    it('renders the plural description when the default organization initially had multiple groups', () => {
      createComponent({
        props: {
          initialDefaultOrgGroupIds: [...defaultOrgGroupIds, 'gid://gitlab/Group/9'],
        },
      });

      expect(findBaseStep().text()).toContain(
        'You have 2 other top-level groups. Drag unassigned groups to your organization, or leave the structure as is. Unassigned groups will not be included in the organization.',
      );
    });
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
    const groups = mockDefaultOrganization.groups.nodes;

    it('renders group cards', () => {
      createComponent();

      const card = findCardAt(1);
      const groupCards = findAllGroupCards(card);

      expect(groupCards).toHaveLength(groups.length);
    });

    it('passes group prop to organization group card', () => {
      createComponent();

      const card = findCardAt(1);
      expect(findAllGroupCards(card).at(0).props('group')).toEqual(groups[0]);
    });

    it('passes organization visibility to organization group card', () => {
      createComponent();

      const card = findCardAt(1);
      expect(findAllGroupCards(card).at(0).props('organizationVisibility')).toBe(
        mockDefaultOrganization.visibility,
      );
    });

    it('only adds a border to the group cards in the default organization', () => {
      createComponent();

      expect(findAllGroupCards(findCardAt(1)).at(0).classes()).toContain('gl-border');
      expect(findAllGroupCards(findCardAt(0)).at(0).classes()).not.toContain('gl-border');
    });
  });

  describe('drag and drop', () => {
    const findAllDraggableComponents = () => wrapper.findAllComponents(Draggable);
    const findDraggable1 = () => findAllDraggableComponents().at(0);
    const findDraggable2 = () => findAllDraggableComponents().at(1);

    const groupToMove = mockDefaultOrganization.groups.nodes[0];

    const updatedOrganizations = [
      {
        ...mockNewOrganization,
        groups: {
          ...mockNewOrganization.groups,
          nodes: [...mockNewOrganization.groups.nodes, groupToMove],
        },
      },
      {
        ...mockDefaultOrganization,
        groups: {
          ...mockDefaultOrganization.groups,
          nodes: [],
        },
      },
    ];

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

    it('puts every draggable in the same group so groups can be moved between organizations', () => {
      createComponent();

      findAllDraggableComponents().wrappers.forEach((draggable) => {
        expect(draggable.props('group')).toBe('organizationGroups');
      });
    });

    describe('which groups can be dragged', () => {
      const DRAGGING_DISABLED_CSS_CLASS = 'organizations-reconciliation-draggable-disabled';
      const NEW_ORG_INDEX = 0;
      const DEFAULT_ORG_INDEX = 1;

      const findGroupCardAt = (cardIndex) => findAllGroupCards(findCardAt(cardIndex)).at(0);

      beforeEach(() => {
        createComponent({ props: { initialDefaultOrgGroupIds: defaultOrgGroupIds } });
      });

      it('filters out groups that were not originally in the default organization', () => {
        findAllDraggableComponents().wrappers.forEach((draggable) => {
          expect(draggable.props('filter')).toBe(`.${DRAGGING_DISABLED_CSS_CLASS}`);
        });
      });

      it('marks groups that were originally in the default organization as draggable', () => {
        const classes = findGroupCardAt(DEFAULT_ORG_INDEX).classes();

        expect(classes).not.toContain(DRAGGING_DISABLED_CSS_CLASS);
        expect(classes).toContain('hover:gl-cursor-grab');
        expect(classes).toContain('hover:gl-shadow-md');
      });

      it('marks groups that were not originally in the default organization as not draggable', () => {
        const classes = findGroupCardAt(NEW_ORG_INDEX).classes();

        expect(classes).toContain(DRAGGING_DISABLED_CSS_CLASS);
        expect(classes).not.toContain('hover:gl-cursor-grab');
        expect(classes).not.toContain('hover:gl-shadow-md');
      });

      describe('move', () => {
        const createMoveEvent = (relatedCssClasses) => {
          const related = document.createElement('div');
          related.classList.add(...relatedCssClasses);

          return { related };
        };

        const callMove = (relatedCssClasses) =>
          findDraggable1().props('move')(createMoveEvent(relatedCssClasses));

        it('places the dragged group after groups that cannot be dragged', () => {
          expect(callMove([DRAGGING_DISABLED_CSS_CLASS])).toBe(1);
        });

        it('lets SortableJS position the dragged group when the group it is moved over can be dragged', () => {
          expect(callMove(['hover:gl-cursor-grab'])).toBe(true);
        });
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

        findDraggable1().vm.$emit('choose');
      });

      it('adds organizations-reconciliation-draggable-dragging CSS class to body', () => {
        expect(document.body.classList.contains(DRAGGING_CSS_CLASS)).toBe(true);
      });

      describe('when item is unchosen', () => {
        it('removes organizations-reconciliation-draggable-dragging CSS class from body', () => {
          findDraggable1().vm.$emit('unchoose');

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

        const draggable1 = findDraggable1();
        const draggable2 = findDraggable2();

        draggable1.vm.$emit('input', [...mockNewOrganization.groups.nodes, groupToMove]);
        draggable2.vm.$emit('input', []);
        draggable2.vm.$emit('end');

        await nextTick();

        expect(wrapper.emitted('update')).toEqual([[updatedOrganizations]]);
      });
    });

    describe('drop zones', () => {
      const OTHER_ORG_INDEX = 0;
      const DEFAULT_ORG_INDEX = 1;

      it('always shows the drop zone for the organization being created', () => {
        createComponent({
          props: {
            organizations: mockOrganizations,
            initialDefaultOrgGroupIds: defaultOrgGroupIds,
          },
        });

        expect(findDropZone(OTHER_ORG_INDEX).exists()).toBe(true);
      });

      describe('when the default organization still holds all of the groups it started with', () => {
        it('hides the default organization drop zone', () => {
          createComponent({
            props: {
              organizations: mockOrganizations,
              initialDefaultOrgGroupIds: defaultOrgGroupIds,
            },
          });

          expect(findDropZone(DEFAULT_ORG_INDEX).exists()).toBe(false);
        });
      });

      describe('when a group has been moved out of the default organization', () => {
        it('shows the default organization drop zone', () => {
          createComponent({
            props: {
              organizations: updatedOrganizations,
              initialDefaultOrgGroupIds: defaultOrgGroupIds,
            },
          });

          expect(findDropZone(DEFAULT_ORG_INDEX).exists()).toBe(true);
        });
      });

      describe('when the default organization started with no groups', () => {
        it('hides the default organization drop zone', () => {
          createComponent({
            props: {
              organizations: updatedOrganizations,
              initialDefaultOrgGroupIds: [],
            },
          });

          expect(findDropZone(DEFAULT_ORG_INDEX).exists()).toBe(false);
        });
      });
    });
  });
});
