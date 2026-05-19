import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlSprintf, GlModal } from '@gitlab/ui';
import organizationsForReconciliationResponse from 'test_fixtures/graphql/organizations/organizations_for_reconciliation.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { createAlert } from '~/alert';
import ReconciliationModal from '~/organizations/index/components/reconciliation/modal.vue';
import SkeletonLoader from '~/organizations/index/components/reconciliation/skeleton_loader.vue';
import organizationsForReconciliationQuery from '~/organizations/index/graphql/queries/organizations_for_reconciliation.query.graphql';
import Step1 from '~/organizations/index/components/reconciliation/steps/step_1.vue';
import Step2 from '~/organizations/index/components/reconciliation/steps/step_2.vue';
import Step3 from '~/organizations/index/components/reconciliation/steps/step_3.vue';
import { mockDefaultOrganization } from 'jest/organizations/shared/mock_data';
import {
  mockOrganizations,
  organizationWithGroupsIndex,
  organizationWithGroups,
  organizationWithoutGroupsIndex,
  organizationWithoutGroups,
} from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('OrganizationReconciliationModal', () => {
  let wrapper;
  let mockApollo;

  const organizationsWithDefault = [
    mockDefaultOrganization,
    ...organizationsForReconciliationResponse.data.organizations.nodes,
  ];
  const responseWithDefault = {
    data: { organizations: { nodes: organizationsWithDefault } },
  };

  const successHandler = jest.fn().mockResolvedValue(organizationsForReconciliationResponse);
  const GlModalStub = stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE });

  const hideAndShowModal = async () => {
    await wrapper.setProps({ visible: false });
    await wrapper.setProps({ visible: true });
    await waitForPromises();
  };

  const createComponent = ({ props = {}, handler = successHandler } = {}) => {
    mockApollo = createMockApollo([[organizationsForReconciliationQuery, handler]]);

    wrapper = shallowMount(ReconciliationModal, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
        GlModal: GlModalStub,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findSkeletonLoader = () => wrapper.findComponent(SkeletonLoader);
  const findStep1 = () => wrapper.findComponent(Step1);
  const findStep2 = () => wrapper.findComponent(Step2);
  const findStep3 = () => wrapper.findComponent(Step3);
  const findPrevButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findNextButton = () => wrapper.findAllComponents(GlButton).at(1);

  it('renders GlModal', () => {
    createComponent();

    expect(findModal().exists()).toBe(true);
  });

  it('passes visible prop to GlModal', () => {
    createComponent({ props: { visible: true } });

    expect(findModal().props('visible')).toBe(true);
  });

  it('defaults visible prop to false', () => {
    createComponent();

    expect(findModal().props('visible')).toBe(false);
  });

  it('emits change event when modal visibility changes', async () => {
    createComponent();

    await findModal().vm.$emit('change', true);

    expect(wrapper.emitted('change')).toEqual([[true]]);
  });

  describe('GraphQL query', () => {
    describe('when modal not visible', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not fetch organizations', () => {
        expect(successHandler).not.toHaveBeenCalled();
      });

      it('passes empty array when organizations have not loaded', () => {
        expect(findStep1().props('organizations')).toEqual([]);
      });
    });

    describe('when modal is visible', () => {
      describe('while loading', () => {
        beforeEach(() => {
          createComponent({ props: { visible: true } });
        });

        it('renders skeleton loader', () => {
          expect(findSkeletonLoader().exists()).toBe(true);
        });

        it('does not render step component', () => {
          expect(findStep1().exists()).toBe(false);
        });

        it('hides the modal footer', () => {
          expect(findModal().attributes('hide-footer')).toBe('true');
        });
      });

      describe('when loaded', () => {
        beforeEach(async () => {
          createComponent({ props: { visible: true } });

          await waitForPromises();
        });

        it('fetches organizations', () => {
          expect(successHandler).toHaveBeenCalled();
        });

        it('does not render skeleton loader', () => {
          expect(findSkeletonLoader().exists()).toBe(false);
        });

        it('shows the modal footer', () => {
          expect(findModal().attributes('hide-footer')).toBeUndefined();
        });

        it('passes organizations to step component', () => {
          expect(findStep1().props('organizations')).toEqual(mockOrganizations);
        });

        it('does not refetch organizations when modal is closed and reopened', async () => {
          expect(successHandler).toHaveBeenCalledTimes(1);

          await hideAndShowModal();

          expect(successHandler).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('when query fails', () => {
      const error = new Error();

      beforeEach(async () => {
        createComponent({
          props: { visible: true },
          handler: jest.fn().mockRejectedValue(error),
        });

        await waitForPromises();
      });

      it('calls createAlert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred fetching organizations. Please try again.',
          error,
          captureError: true,
        });
      });
    });
  });

  describe('footer buttons', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders prev and next buttons', () => {
      expect(findPrevButton().exists()).toBe(true);
      expect(findNextButton().exists()).toBe(true);
    });

    it('renders cancel text for prev button on first step', () => {
      expect(findPrevButton().text()).toBe('Cancel');
    });

    it('renders continue text for next button', () => {
      expect(findNextButton().text()).toBe('Continue');
    });
  });

  describe('step components', () => {
    describe('step 1', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders step 1 component', () => {
        expect(findStep1().exists()).toBe(true);
      });

      it('displays step progress text', () => {
        expect(findModal().text()).toContain('Step 1 / 3');
      });

      it('next button advances to step 2', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        expect(findStep2().exists()).toBe(true);
      });

      it('prev button closes modal', async () => {
        findPrevButton().vm.$emit('click');
        await nextTick();

        expect(wrapper.emitted('change')).toEqual([[false]]);
      });
    });

    describe('step 2', () => {
      beforeEach(async () => {
        createComponent({ props: { visible: true } });

        await waitForPromises();

        findNextButton().vm.$emit('click');
        await nextTick();
      });

      it('renders step 2 component', () => {
        expect(findStep2().exists()).toBe(true);
      });

      it('displays step progress text', () => {
        expect(findModal().text()).toContain('Step 2 / 3');
      });

      it('renders back text for prev button', () => {
        expect(findPrevButton().text()).toBe('Back');
      });

      it('next button advances to step 3', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        expect(wrapper.findComponent(Step3).exists()).toBe(true);
      });

      it('prev button returns to step 1', async () => {
        findPrevButton().vm.$emit('click');
        await nextTick();

        expect(wrapper.findComponent(Step1).exists()).toBe(true);
      });

      describe('when update event is fired', () => {
        const groupToMoveIndex = 0;
        const groupToMove = organizationWithGroups.groups.nodes[groupToMoveIndex];

        const updatedOrganizations = mockOrganizations
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

        it('updates organizations prop', async () => {
          expect(findStep2().props('organizations')).toEqual(mockOrganizations);
          findStep2().vm.$emit('update', updatedOrganizations);

          await nextTick();

          expect(findStep2().props('organizations')).toEqual(updatedOrganizations);
        });

        it('retains organization updates after hiding and showing modal', async () => {
          expect(findStep2().props('organizations')).toEqual(mockOrganizations);
          findStep2().vm.$emit('update', updatedOrganizations);

          await nextTick();

          expect(findStep2().props('organizations')).toEqual(updatedOrganizations);

          await hideAndShowModal();

          expect(findStep2().props('organizations')).toEqual(updatedOrganizations);
        });
      });
    });

    describe('step 3', () => {
      beforeEach(async () => {
        createComponent();

        findNextButton().vm.$emit('click');
        await nextTick();

        findNextButton().vm.$emit('click');
        await nextTick();
      });

      it('renders step 3 component', () => {
        expect(findStep3().exists()).toBe(true);
      });

      it('displays step progress text', () => {
        expect(findModal().text()).toContain('Step 3 / 3');
      });

      it('renders confirm text for next button', () => {
        expect(findNextButton().text()).toBe('Confirm');
      });

      it('next button does nothing and stays on step 3', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        expect(wrapper.findComponent(Step3).exists()).toBe(true);
      });

      it('prev button returns to step 2', async () => {
        findPrevButton().vm.$emit('click');
        await nextTick();

        expect(wrapper.findComponent(Step2).exists()).toBe(true);
      });
    });

    describe('default organization exclusion', () => {
      const handlerWithDefault = jest.fn().mockResolvedValue(responseWithDefault);

      beforeEach(async () => {
        createComponent({ props: { visible: true }, handler: handlerWithDefault });

        await waitForPromises();
      });

      it('excludes default organization from step 1', () => {
        const step1Orgs = findStep1().props('organizations');

        expect(step1Orgs).not.toEqual(
          expect.arrayContaining([expect.objectContaining({ id: mockDefaultOrganization.id })]),
        );
      });

      it('includes default organization in step 2', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        const step2Orgs = findStep2().props('organizations');

        expect(step2Orgs).toEqual(
          expect.arrayContaining([expect.objectContaining({ id: mockDefaultOrganization.id })]),
        );
      });

      it('excludes default organization from step 3', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        findNextButton().vm.$emit('click');
        await nextTick();

        const step3Orgs = findStep3().props('organizations');

        expect(step3Orgs).not.toEqual(
          expect.arrayContaining([expect.objectContaining({ id: mockDefaultOrganization.id })]),
        );
      });
    });
  });
});
