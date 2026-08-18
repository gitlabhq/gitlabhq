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

  describe('step description', () => {
    it('renders the singular description when the default organization has one group', () => {
      createComponent();

      expect(findBaseStep().text()).toContain(
        'You have 1 other top-level group. Drag unassigned groups to your organization, or leave the structure as is. Unassigned groups will not be included in the organization.',
      );
    });

    it('renders the plural description when the default organization has multiple groups', () => {
      const [group] = mockDefaultOrganization.groups.nodes;

      createComponent({
        props: {
          organizations: [
            mockNewOrganization,
            {
              ...mockDefaultOrganization,
              groups: { ...mockDefaultOrganization.groups, nodes: [group, { ...group, id: 2 }] },
            },
          ],
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

    describe('default organization drop zone', () => {
      const OTHER_ORG_INDEX = 0;
      const DEFAULT_ORG_INDEX = 1;

      const startDragFromOrg = async (orgIndex) => {
        findAllDraggableComponents().at(orgIndex).vm.$emit('start', { oldIndex: 1 });
        await nextTick();
      };

      describe('when all initial groups are still in the default organization', () => {
        beforeEach(() => {
          createComponent({
            props: {
              organizations: mockOrganizations,
              initialDefaultOrgGroupIds: mockDefaultOrganization.groups.nodes.map(
                (group) => group.id,
              ),
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
              organizations: updatedOrganizations,
              initialDefaultOrgGroupIds: mockDefaultOrganization.groups.nodes.map(
                (group) => group.id,
              ),
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
              organizations: updatedOrganizations,
              initialDefaultOrgGroupIds: mockDefaultOrganization.groups.nodes.map(
                (group) => group.id,
              ),
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
              organizations: updatedOrganizations,
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
