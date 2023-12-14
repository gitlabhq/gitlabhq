import { GlLink, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/issues/constants';
import { timeFor } from '~/lib/utils/datetime_utility';
import SidebarDropdown from '~/sidebar/components/sidebar_dropdown.vue';
import SidebarDropdownWidget from '~/sidebar/components/sidebar_dropdown_widget.vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { IssuableAttributeType } from '~/sidebar/constants';
import projectIssueMilestoneMutation from '~/sidebar/queries/project_issue_milestone.mutation.graphql';
import projectIssueMilestoneQuery from '~/sidebar/queries/project_issue_milestone.query.graphql';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';

import {
  mockIssue,
  mockProjectMilestonesResponse,
  noCurrentMilestoneResponse,
  mockMilestoneMutationResponse,
  mockMilestone2,
} from '../mock_data';

jest.mock('~/alert');

describe('SidebarDropdownWidget', () => {
  let wrapper;
  let mockApollo;

  const promiseData = { issuableSetAttribute: { issue: { attribute: { id: '123' } } } };
  const firstErrorMsg = 'first error';
  const promiseWithErrors = {
    ...promiseData,
    issuableSetAttribute: { ...promiseData.issuableSetAttribute, errors: [firstErrorMsg] },
  };

  const mutationSuccess = () => jest.fn().mockResolvedValue({ data: promiseData });
  const mutationError = () =>
    jest.fn().mockRejectedValue('Failed to set milestone on this issue. Please try again.');
  const mutationSuccessWithErrors = () => jest.fn().mockResolvedValue({ data: promiseWithErrors });

  const findGlLink = () => wrapper.findComponent(GlLink);
  const findDateTooltip = () => getBinding(findGlLink().element, 'gl-tooltip');
  const findSidebarDropdown = () => wrapper.findComponent(SidebarDropdown);
  const findSidebarEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findEditButton = () => findSidebarEditableItem().find('[data-testid="edit-button"]');
  const findEditableLoadingIcon = () => findSidebarEditableItem().findComponent(GlLoadingIcon);
  const findSelectedAttribute = () => wrapper.findByTestId('select-milestone');

  const waitForDropdown = async () => {
    // BDropdown first changes its `visible` property
    // in a requestAnimationFrame callback.
    // It then emits `shown` event in a watcher for `visible`
    // Hence we need both of these:
    await waitForPromises();
    await nextTick();
  };

  const waitForApollo = async () => {
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  // Used with createComponentWithApollo which uses 'mount'
  const clickEdit = async () => {
    await findEditButton().trigger('click');

    await waitForDropdown();

    // We should wait for attributes list to be fetched.
    await waitForApollo();
  };

  // Used with createComponent which shallow mounts components
  const toggleDropdown = async () => {
    wrapper.vm.$refs.editable.expand();

    await waitForDropdown();
  };

  const createComponentWithApollo = async ({
    requestHandlers = [],
    projectMilestonesSpy = jest.fn().mockResolvedValue(mockProjectMilestonesResponse),
    currentMilestoneSpy = jest.fn().mockResolvedValue(noCurrentMilestoneResponse),
  } = {}) => {
    Vue.use(VueApollo);

    mockApollo = createMockApollo([
      [projectMilestonesQuery, projectMilestonesSpy],
      [projectIssueMilestoneQuery, currentMilestoneSpy],
      ...requestHandlers,
    ]);

    wrapper = mountExtended(SidebarDropdownWidget, {
      provide: { canUpdate: true },
      apolloProvider: mockApollo,
      propsData: {
        workspacePath: mockIssue.projectPath,
        attrWorkspacePath: mockIssue.projectPath,
        iid: mockIssue.iid,
        issuableType: TYPE_ISSUE,
        issuableAttribute: IssuableAttributeType.Milestone,
      },
      attachTo: document.body,
    });

    await waitForApollo();
  };

  const createComponent = ({ data = {}, mutationPromise = mutationSuccess, queries = {} } = {}) => {
    wrapper = shallowMountExtended(SidebarDropdownWidget, {
      provide: { canUpdate: true },
      data() {
        return data;
      },
      propsData: {
        workspacePath: '',
        attrWorkspacePath: '',
        iid: '',
        issuableType: TYPE_ISSUE,
        issuableAttribute: IssuableAttributeType.Milestone,
      },
      mocks: {
        $apollo: {
          mutate: mutationPromise(),
          queries: {
            issuable: { loading: false },
            attributesList: { loading: false },
            ...queries,
          },
        },
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        SidebarEditableItem,
        GlSearchBoxByType,
        SidebarDropdown: stubComponent(SidebarDropdown, {
          methods: { show: jest.fn() },
        }),
      },
    });
  };

  describe('when not editing', () => {
    beforeEach(() => {
      createComponent({
        data: {
          issuable: {
            attribute: { id: 'id', title: 'title', webUrl: 'webUrl', dueDate: '2021-09-09' },
          },
        },
        stubs: {
          SidebarEditableItem,
        },
      });
    });

    it('shows the current attribute', () => {
      expect(findSelectedAttribute().text()).toBe('title');
    });

    it('links to the current attribute', () => {
      expect(findGlLink().attributes().href).toBe('webUrl');
    });

    it('does not show a loading spinner next to the heading', () => {
      expect(findEditableLoadingIcon().exists()).toBe(false);
    });

    it('shows a loading spinner while fetching the current attribute', () => {
      createComponent({
        queries: {
          issuable: { loading: true },
        },
      });

      expect(findEditableLoadingIcon().exists()).toBe(true);
    });

    it('shows the loading spinner and the title of the selected attribute while updating', () => {
      createComponent({
        data: {
          updating: true,
          selectedTitle: 'Some milestone title',
        },
        queries: {
          issuable: { loading: false },
        },
      });

      expect(findEditableLoadingIcon().exists()).toBe(true);
      expect(findSelectedAttribute().text()).toBe('Some milestone title');
    });

    it('displays time for milestone due date in tooltip', () => {
      expect(findDateTooltip().value).toBe(timeFor('2021-09-09'));
    });

    describe('when current attribute does not exist', () => {
      it('renders "None" as the selected attribute title', () => {
        createComponent();

        expect(findSelectedAttribute().text()).toBe('None');
      });
    });

    describe("when user doesn't have permission to view current attribute", () => {
      it('renders no permission text', () => {
        createComponent({
          data: {
            hasCurrentAttribute: true,
            issuable: {},
          },
          queries: {
            issuable: { loading: false },
          },
        });

        expect(findSelectedAttribute().text()).toBe(
          `You don't have permission to view this ${wrapper.props('issuableAttribute')}.`,
        );
      });
    });
  });

  describe('when a user can edit', () => {
    describe('when user is editing', () => {
      describe('when rendering the dropdown', () => {
        describe('when clicking on dropdown item', () => {
          describe('when currentAttribute is not equal to attribute id', () => {
            describe('when error', () => {
              const bootstrapComponent = (mutationResp) => {
                createComponent({
                  data: {
                    attributesList: [
                      { id: '123', title: '123' },
                      { id: 'id', title: 'title' },
                    ],
                    issuable: {
                      attribute: { id: '123' },
                    },
                  },
                  mutationPromise: mutationResp,
                });
              };

              describe.each`
                description                 | mutationResp                 | expectedMsg
                ${'top-level error'}        | ${mutationError}             | ${'Failed to set milestone on this issue. Please try again.'}
                ${'user-recoverable error'} | ${mutationSuccessWithErrors} | ${firstErrorMsg}
              `(`$description`, ({ mutationResp, expectedMsg }) => {
                beforeEach(async () => {
                  bootstrapComponent(mutationResp);

                  await toggleDropdown();

                  findSidebarDropdown().vm.$emit('change', { id: 'error' });
                });

                it(`calls createAlert with "${expectedMsg}"`, async () => {
                  await nextTick();
                  expect(createAlert).toHaveBeenCalledWith({
                    message: expectedMsg,
                    captureError: true,
                    error: expectedMsg,
                  });
                });
              });
            });
          });
        });
      });
    });
  });

  describe('with mock apollo', () => {
    let error;

    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      error = new Error('mayday');
    });

    describe("when issuable type is 'issue'", () => {
      describe('when dropdown is expanded and user can edit', () => {
        let milestoneMutationSpy;
        beforeEach(async () => {
          milestoneMutationSpy = jest.fn().mockResolvedValue(mockMilestoneMutationResponse);

          await createComponentWithApollo({
            requestHandlers: [[projectIssueMilestoneMutation, milestoneMutationSpy]],
          });

          await clickEdit();
        });

        describe('when currentAttribute is not equal to attribute id', () => {
          describe('when update is successful', () => {
            it('calls setIssueAttribute mutation', () => {
              findSidebarDropdown().vm.$emit('change', { id: mockMilestone2.id });

              expect(milestoneMutationSpy).toHaveBeenCalledWith({
                iid: mockIssue.iid,
                attributeId: getIdFromGraphQLId(mockMilestone2.id),
                fullPath: mockIssue.projectPath,
              });
            });
          });
        });
      });

      describe('currentAttributes', () => {
        it('should call createAlert if currentAttributes query fails', async () => {
          await createComponentWithApollo({
            currentMilestoneSpy: jest.fn().mockRejectedValue(error),
          });

          expect(createAlert).toHaveBeenCalledWith({
            message: wrapper.vm.i18n.currentFetchError,
            captureError: true,
            error: expect.any(Error),
          });
        });
      });
    });
  });
});
