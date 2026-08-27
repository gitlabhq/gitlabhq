import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import { GlButton, GlSprintf, GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_CREATED, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { createOrganizationFromGroupPath } from '~/lib/utils/path_helpers/group';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';
import { DEFAULT_ORGANIZATION_GID } from '~/organizations/shared/constants';
import ReconciliationModal from '~/groups/settings/create_organization/components/modal.vue';
import SkeletonLoader from '~/groups/settings/create_organization/components/skeleton_loader.vue';
import groupsQuery from '~/groups/settings/create_organization/graphql/queries/groups.query.graphql';
import transferGroupsAndConfirmOrganizationMutation from '~/groups/settings/create_organization/graphql/mutations/transfer_groups_and_confirm_organization.mutation.graphql';
import Step1 from '~/groups/settings/create_organization/components/steps/step_1.vue';
import Step2 from '~/groups/settings/create_organization/components/steps/step_2.vue';
import Step3 from '~/groups/settings/create_organization/components/steps/step_3.vue';
import {
  groupsQueryResponse,
  groupsQueryResponseWithoutDefaultOrgGroups,
  mockGroup,
  mockDefaultOrganization,
  mockDefaultGroupOrganization,
  mockBackfilledGroupOrganization,
  mockBackfilledOrganization,
  mockNewOrganization,
  mockOrganizations,
} from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('OrganizationReconciliationModal', () => {
  let wrapper;
  let mockApollo;
  let axiosMock;

  const defaultPropsData = {
    groupFullPath: 'mock-group',
    groupGid: mockGroup.id,
    groupOrganization: mockDefaultGroupOrganization,
  };

  // `POST create_organization_from_group` in step 3 serializes the ID as an integer, so the
  // component has to convert it before handing it to the mutation.
  const createdOrganizationId = 2;
  const createdOrganizationGid = convertToGraphQLId(TYPE_ORGANIZATION, createdOrganizationId);
  const createOrganizationPath = createOrganizationFromGroupPath(defaultPropsData.groupFullPath);

  const alertContainerSelector = '.js-organization-reconciliation-modal-alert-container';

  const successHandler = jest.fn().mockResolvedValue(groupsQueryResponse);
  const confirmMutationHandler = jest.fn().mockResolvedValue({
    data: {
      organizationConfirm: {
        organization: {
          id: createdOrganizationGid,
          __typename: 'Organization',
        },
        errors: [],
        __typename: 'OrganizationConfirmPayload',
      },
    },
  });
  const GlModalStub = stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE });

  const hideAndShowModal = async () => {
    await wrapper.setProps({ visible: false });
    await wrapper.setProps({ visible: true });
    await waitForPromises();
  };

  const createComponent = ({
    props = {},
    handler = successHandler,
    mutationHandler = confirmMutationHandler,
  } = {}) => {
    mockApollo = createMockApollo([
      [groupsQuery, handler],
      [transferGroupsAndConfirmOrganizationMutation, mutationHandler],
    ]);

    wrapper = shallowMount(ReconciliationModal, {
      apolloProvider: mockApollo,
      propsData: {
        ...defaultPropsData,
        ...props,
      },
      stubs: {
        GlSprintf,
        GlModal: GlModalStub,
      },
    });
  };

  const createComponentAndLoad = async (options = {}) => {
    createComponent({ ...options, props: { visible: true, ...options.props } });

    await waitForPromises();
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    axiosMock
      .onPost(createOrganizationPath)
      .reply(HTTP_STATUS_CREATED, { id: createdOrganizationId });
  });

  afterEach(() => {
    axiosMock.restore();
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

      it('does not fetch groups', () => {
        expect(successHandler).not.toHaveBeenCalled();
      });

      it('does not render a step component when organizations have not loaded', () => {
        expect(findStep1().exists()).toBe(false);
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
          await createComponentAndLoad();
        });

        it('fetches the group and the default organization, excluding the group', () => {
          expect(successHandler).toHaveBeenCalledWith({
            defaultOrganizationGid: DEFAULT_ORGANIZATION_GID,
            groupFullPath: defaultPropsData.groupFullPath,
            groupGid: defaultPropsData.groupGid,
          });
        });

        it('does not render skeleton loader', () => {
          expect(findSkeletonLoader().exists()).toBe(false);
        });

        it('shows the modal footer', () => {
          expect(findModal().attributes('hide-footer')).toBeUndefined();
        });

        it('passes the organization to be created to step component', () => {
          expect(findStep1().props('organization')).toEqual(mockNewOrganization);
        });

        it('does not refetch when modal is closed and reopened', async () => {
          expect(successHandler).toHaveBeenCalledTimes(1);

          await hideAndShowModal();

          expect(successHandler).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('when query fails', () => {
      const error = new Error();

      beforeEach(async () => {
        await createComponentAndLoad({ handler: jest.fn().mockRejectedValue(error) });
      });

      it('calls createAlert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred fetching organizations. Please try again.',
          error,
          captureError: true,
          containerSelector: alertContainerSelector,
        });
      });

      it('does not render a step component', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
        expect(findStep1().exists()).toBe(false);
      });
    });
  });

  describe('when the group is still in the default organization', () => {
    beforeEach(async () => {
      await createComponentAndLoad();
    });

    it('renders a placeholder organization built from the group', () => {
      expect(findStep1().props('organization')).toEqual(mockNewOrganization);
    });
  });

  describe('when the group has already been backfilled into its own organization', () => {
    beforeEach(async () => {
      await createComponentAndLoad({
        props: { groupOrganization: mockBackfilledGroupOrganization },
      });
    });

    it("renders the group's existing organization", () => {
      expect(findStep1().props('organization')).toEqual(mockBackfilledOrganization);
    });
  });

  describe('footer buttons', () => {
    beforeEach(async () => {
      await createComponentAndLoad();
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
    const groupToMoveIndex = 0;
    const groupToMove = mockDefaultOrganization.groups.nodes[groupToMoveIndex];

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
    describe('step 1', () => {
      beforeEach(async () => {
        await createComponentAndLoad();
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
        await createComponentAndLoad();

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
      const goToStep3 = async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        findNextButton().vm.$emit('click');
        await nextTick();
      };

      beforeEach(async () => {
        await createComponentAndLoad();
      });

      it('renders step 3 component', async () => {
        await goToStep3();
        expect(findStep3().exists()).toBe(true);
      });

      it('displays step progress text', async () => {
        await goToStep3();
        expect(findModal().text()).toContain('Step 3 / 3');
      });

      it('renders confirm text for next button', async () => {
        await goToStep3();
        expect(findNextButton().text()).toBe('Confirm');
      });

      it('prev button returns to step 2', async () => {
        await goToStep3();

        findPrevButton().vm.$emit('click');
        await nextTick();

        expect(wrapper.findComponent(Step2).exists()).toBe(true);
      });

      describe('confirming', () => {
        const createErrorMessage =
          'An error occurred creating your organization. Please reload the page and try again.';
        const confirmErrorMessage =
          'An error occurred transferring groups into your organization. Please reload the page and try again.';

        const moveGroupToOrganization = async (organization) => {
          findStep2().vm.$emit('update', [
            { ...organization, groups: { nodes: [...organization.groups.nodes, groupToMove] } },
            { ...mockDefaultOrganization, groups: { nodes: [] } },
          ]);

          await nextTick();
        };

        const goToStep3AndConfirm = async () => {
          findNextButton().vm.$emit('click');
          await nextTick();

          await moveGroupToOrganization(findStep2().props('organizations')[0]);

          findNextButton().vm.$emit('click');
          await nextTick();

          findNextButton().vm.$emit('click');
          await waitForPromises();
        };

        describe('when the group is still in the default organization', () => {
          beforeEach(async () => {
            await createComponentAndLoad();
            await goToStep3AndConfirm();
          });

          it('creates the organization from the group', () => {
            expect(axiosMock.history.post).toHaveLength(1);
            expect(axiosMock.history.post[0].url).toBe(createOrganizationPath);
          });

          it('transfers the moved groups to the created organization and confirms it', () => {
            expect(confirmMutationHandler).toHaveBeenCalledWith({
              organizationId: createdOrganizationGid,
              groupIds: [groupToMove.id],
            });
          });

          it('does not call createAlert', () => {
            expect(createAlert).not.toHaveBeenCalled();
          });
        });

        describe('when the group has already been backfilled into its own organization', () => {
          beforeEach(async () => {
            await createComponentAndLoad({
              props: { groupOrganization: mockBackfilledGroupOrganization },
            });
            await goToStep3AndConfirm();
          });

          it('does not create a new organization', () => {
            expect(axiosMock.history.post).toHaveLength(0);
          });

          it("transfers the moved groups to the group's organization and confirms it", () => {
            expect(confirmMutationHandler).toHaveBeenCalledWith({
              organizationId: mockBackfilledGroupOrganization.id,
              groupIds: [groupToMove.id],
            });
          });
        });

        describe('when no groups have been moved', () => {
          beforeEach(async () => {
            await createComponentAndLoad();

            findNextButton().vm.$emit('click');
            await nextTick();

            findNextButton().vm.$emit('click');
            await nextTick();

            findNextButton().vm.$emit('click');
            await waitForPromises();
          });

          it('confirms the organization without transferring any groups', () => {
            expect(confirmMutationHandler).toHaveBeenCalledWith({
              organizationId: createdOrganizationGid,
              groupIds: [],
            });
          });

          it('does not include the current group', () => {
            expect(confirmMutationHandler).not.toHaveBeenCalledWith(
              expect.objectContaining({ groupIds: [mockGroup.id] }),
            );
          });
        });

        describe('loading state', () => {
          beforeEach(async () => {
            await createComponentAndLoad();

            findNextButton().vm.$emit('click');
            await nextTick();

            findNextButton().vm.$emit('click');
            await nextTick();
          });

          it('is not loading before confirming', () => {
            expect(findNextButton().props('loading')).toBe(false);
          });

          it('loads while confirming and stops once done', async () => {
            findNextButton().vm.$emit('click');
            await nextTick();

            expect(findNextButton().props('loading')).toBe(true);

            await waitForPromises();

            expect(findNextButton().props('loading')).toBe(false);
          });
        });

        describe('when creating the organization fails', () => {
          beforeEach(async () => {
            axiosMock.onPost(createOrganizationPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

            await createComponentAndLoad();
            await goToStep3AndConfirm();
          });

          it('calls createAlert', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: createErrorMessage,
              error: expect.any(Error),
              captureError: true,
              containerSelector: alertContainerSelector,
            });
          });

          it('does not confirm the organization', () => {
            expect(confirmMutationHandler).not.toHaveBeenCalled();
          });

          it('stops loading the next button', () => {
            expect(findNextButton().props('loading')).toBe(false);
          });
        });

        describe('when confirming the organization fails', () => {
          const error = new Error();

          beforeEach(async () => {
            await createComponentAndLoad({
              mutationHandler: jest.fn().mockRejectedValue(error),
            });
            await goToStep3AndConfirm();
          });

          it('calls createAlert', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: confirmErrorMessage,
              error,
              captureError: true,
              containerSelector: alertContainerSelector,
            });
          });

          it('stops loading the next button', () => {
            expect(findNextButton().props('loading')).toBe(false);
          });
        });

        describe('when confirming the organization responds with errors', () => {
          const errors = ['Insufficient permissions', 'One or more groups could not be found'];

          beforeEach(async () => {
            await createComponentAndLoad({
              mutationHandler: jest.fn().mockResolvedValue({
                data: {
                  organizationConfirm: {
                    organization: null,
                    errors,
                    __typename: 'OrganizationConfirmPayload',
                  },
                },
              }),
            });
            await goToStep3AndConfirm();
          });

          it('calls createAlert with the returned errors', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: confirmErrorMessage,
              error: new Error(errors.join(', ')),
              captureError: true,
              containerSelector: alertContainerSelector,
            });
          });

          it('stops loading the next button', () => {
            expect(findNextButton().props('loading')).toBe(false);
          });
        });
      });
    });

    describe('step component props', () => {
      beforeEach(async () => {
        await createComponentAndLoad();
      });

      it('passes organization prop to step 1', () => {
        expect(findStep1().props('organization')).toEqual(mockNewOrganization);
      });

      it('organizations prop to step 2', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        expect(findStep2().props('organizations')).toEqual(
          expect.arrayContaining([expect.objectContaining({ id: mockDefaultOrganization.id })]),
        );
      });

      it('passes organization prop to step 3', async () => {
        findNextButton().vm.$emit('click');
        await nextTick();

        findNextButton().vm.$emit('click');
        await nextTick();

        expect(findStep3().props('organization')).toEqual(mockNewOrganization);
      });
    });

    describe('initialDefaultOrgGroupIds persistence', () => {
      const expectedInitialDefaultOrgGroupIds = mockDefaultOrganization.groups.nodes.map(
        (group) => group.id,
      );

      beforeEach(async () => {
        await createComponentAndLoad();

        findNextButton().vm.$emit('click');
        await nextTick();
      });

      it('passes initial default organization group IDs to step 2', () => {
        expect(findStep2().props('initialDefaultOrgGroupIds')).toEqual(
          expectedInitialDefaultOrgGroupIds,
        );
      });

      it('retains initial default organization group IDs after moving a group and navigating to step 3 and back', async () => {
        findStep2().vm.$emit('update', updatedOrganizations);
        await nextTick();

        findNextButton().vm.$emit('click');
        await nextTick();

        expect(findStep3().exists()).toBe(true);

        findPrevButton().vm.$emit('click');
        await nextTick();

        expect(findStep2().props('organizations')).toEqual(updatedOrganizations);
        expect(findStep2().props('initialDefaultOrgGroupIds')).toEqual(
          expectedInitialDefaultOrgGroupIds,
        );
      });
    });
  });

  describe('when default organization has no other groups', () => {
    beforeEach(async () => {
      await createComponentAndLoad({
        handler: jest.fn().mockResolvedValue(groupsQueryResponseWithoutDefaultOrgGroups),
      });
    });

    it('renders step 1 with a total of two steps', () => {
      expect(findStep1().exists()).toBe(true);
      expect(findModal().text()).toContain('Step 1 / 2');
    });

    describe('when next button is clicked', () => {
      beforeEach(async () => {
        findNextButton().vm.$emit('click');
        await nextTick();
      });

      it('skips step 2 and renders step 3', () => {
        expect(findStep2().exists()).toBe(false);
        expect(findStep3().exists()).toBe(true);
        expect(findModal().text()).toContain('Step 2 / 2');
      });

      it('renders confirm text for next button', () => {
        expect(findNextButton().text()).toBe('Confirm');
      });

      it('prev button returns to step 1', async () => {
        findPrevButton().vm.$emit('click');
        await nextTick();

        expect(findStep1().exists()).toBe(true);
      });
    });
  });
});
