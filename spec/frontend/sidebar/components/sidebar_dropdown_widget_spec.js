import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/issues/constants';
import SidebarDropdownWidget from '~/sidebar/components/sidebar_dropdown_widget.vue';
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
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findEditButton = () => wrapper.findByTestId('milestone-edit');
  const findLoadingIcon = () => wrapper.findByTestId('loading-icon');
  const findSelectedAttribute = () => wrapper.findByTestId('select-milestone');

  const waitForApollo = async () => {
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  // Used with createComponentWithApollo which uses 'mount'
  const clickEdit = async () => {
    findListbox().vm.$emit('shown');

    await waitForApollo();
  };

  const createComponentWithApollo = async ({
    requestHandlers = [],
    projectMilestonesSpy = jest.fn().mockResolvedValue(mockProjectMilestonesResponse),
    currentMilestoneSpy = jest.fn().mockResolvedValue(noCurrentMilestoneResponse),
    canUpdate = true,
  } = {}) => {
    Vue.use(VueApollo);

    mockApollo = createMockApollo([
      [projectMilestonesQuery, projectMilestonesSpy],
      [projectIssueMilestoneQuery, currentMilestoneSpy],
      ...requestHandlers,
    ]);

    wrapper = mountExtended(SidebarDropdownWidget, {
      provide: { canUpdate },
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

  const createComponent = ({
    data = {},
    mutationPromise = mutationSuccess,
    queries = {},
    issuableAttribute = IssuableAttributeType.Milestone,
    canUpdate = true,
  } = {}) => {
    wrapper = shallowMountExtended(SidebarDropdownWidget, {
      provide: { canUpdate },
      data() {
        return data;
      },
      propsData: {
        workspacePath: '',
        attrWorkspacePath: '',
        iid: '',
        issuableType: TYPE_ISSUE,
        issuableAttribute,
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
    });
  };

  describe('when not editing', () => {
    beforeEach(() => {
      createComponent({
        data: {
          issuable: {
            attribute: {
              id: 'gid://gitlab/Milestone/1',
              title: 'title',
              webUrl: 'webUrl',
              dueDate: '2021-09-09',
            },
          },
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
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows a loading spinner while fetching the current attribute', () => {
      createComponent({
        queries: {
          issuable: { loading: true },
        },
      });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('shows the title of the selected attribute while updating', () => {
      createComponent({
        data: {
          updating: true,
          selectedTitle: 'Some milestone title',
        },
        queries: {
          issuable: { loading: false },
        },
      });

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findSelectedAttribute().text()).toBe('Some milestone title');
    });

    it('does not display tooltip for milestone when popover is supported', () => {
      expect(findDateTooltip().value).toBeNull();
    });

    it('applies popover attributes to the milestone link', () => {
      expect(findGlLink().attributes()).toMatchObject({
        'data-reference-type': 'milestone',
        'data-placement': 'left',
        'data-milestone': '1',
      });
      expect(findGlLink().classes()).toContain('has-popover');
    });

    describe('when popover is not supported', () => {
      beforeEach(() => {
        createComponent({
          issuableAttribute: 'labels',
          data: {
            issuable: {
              attribute: {
                id: 'gid://gitlab/Label/1',
              },
            },
          },
        });
      });

      it('displays tooltip', () => {
        expect(findDateTooltip().value).not.toBeNull();
      });

      it('does not apply popover attributes to the link', () => {
        expect(findGlLink().classes()).not.toContain('has-popover');
        expect(findGlLink().attributes('data-reference-type')).toBeUndefined();
      });
    });

    describe('when current attribute does not exist', () => {
      it('renders "None" as the selected attribute title', () => {
        createComponent();

        expect(findSelectedAttribute().text()).toBe('None');
      });
    });
  });

  describe('edit toggle button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('preserves the shortcut-sidebar-dropdown-toggle class for keyboard shortcuts', () => {
      expect(findEditButton().classes()).toContain('shortcut-sidebar-dropdown-toggle');
    });

    it('uses tracking attributes for analytics', () => {
      expect(findEditButton().attributes()).toMatchObject({
        'data-track-action': 'click_edit_button',
        'data-track-label': 'right_sidebar',
        'data-track-property': 'milestone',
      });
    });
  });

  describe('when a user cannot edit', () => {
    beforeEach(() => {
      createComponent({ canUpdate: false });
    });

    it('does not render the edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('does not render the listbox', () => {
      expect(findListbox().exists()).toBe(false);
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
                beforeEach(() => {
                  bootstrapComponent(mutationResp);

                  findListbox().vm.$emit('select', 'id');
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
              findListbox().vm.$emit('select', mockMilestone2.id);

              expect(milestoneMutationSpy).toHaveBeenCalledWith({
                iid: mockIssue.iid,
                attributeId: getIdFromGraphQLId(mockMilestone2.id),
                fullPath: mockIssue.projectPath,
              });
            });
          });
        });

        it('exposes the listbox accessibilityAttributes on the toggle button', () => {
          // The listbox's scoped #toggle slot provides accessibilityAttributes
          // (e.g. aria-haspopup, aria-expanded). We spread them onto the Edit
          // button so it is a proper ARIA combobox trigger.
          expect(findEditButton().attributes('aria-haspopup')).toBeDefined();
        });

        describe('when reset (no milestone) is selected', () => {
          it('calls the mutation with a null attribute id', () => {
            findListbox().vm.$emit('reset');

            expect(milestoneMutationSpy).toHaveBeenCalledWith({
              iid: mockIssue.iid,
              attributeId: null,
              fullPath: mockIssue.projectPath,
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
