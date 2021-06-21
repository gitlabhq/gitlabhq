import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlLink,
  GlSearchBoxByType,
  GlFormInput,
  GlLoadingIcon,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { IssuableType } from '~/issue_show/constants';
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
  emptyProjectMilestonesResponse,
} from '../mock_data';

jest.mock('~/flash');

const localVue = createLocalVue();

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
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownText = () => wrapper.findComponent(GlDropdownText);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemWithText = (text) =>
    findAllDropdownItems().wrappers.find((x) => x.text() === text);

  const findSidebarEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findEditButton = () => findSidebarEditableItem().find('[data-testid="edit-button"]');
  const findEditableLoadingIcon = () => findSidebarEditableItem().findComponent(GlLoadingIcon);
  const findAttributeItems = () => wrapper.findByTestId('milestone-items');
  const findSelectedAttribute = () => wrapper.findByTestId('select-milestone');
  const findNoAttributeItem = () => wrapper.findByTestId('no-milestone-item');
  const findLoadingIconDropdown = () => wrapper.findByTestId('loading-icon-dropdown');

  const waitForDropdown = async () => {
    // BDropdown first changes its `visible` property
    // in a requestAnimationFrame callback.
    // It then emits `shown` event in a watcher for `visible`
    // Hence we need both of these:
    await waitForPromises();
    await wrapper.vm.$nextTick();
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
    localVue.use(VueApollo);
    mockApollo = createMockApollo([
      [projectMilestonesQuery, projectMilestonesSpy],
      [projectIssueMilestoneQuery, currentMilestoneSpy],
      ...requestHandlers,
    ]);

    wrapper = extendedWrapper(
      mount(SidebarDropdownWidget, {
        localVue,
        provide: { canUpdate: true },
        apolloProvider: mockApollo,
        propsData: {
          workspacePath: mockIssue.projectPath,
          attrWorkspacePath: mockIssue.projectPath,
          iid: mockIssue.iid,
          issuableType: IssuableType.Issue,
          issuableAttribute: IssuableAttributeType.Milestone,
        },
        attachTo: document.body,
      }),
    );

    await waitForApollo();
  };

  const createComponent = ({ data = {}, mutationPromise = mutationSuccess, queries = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(SidebarDropdownWidget, {
        provide: { canUpdate: true },
        data() {
          return data;
        },
        propsData: {
          workspacePath: '',
          attrWorkspacePath: '',
          iid: '',
          issuableType: IssuableType.Issue,
          issuableAttribute: IssuableAttributeType.Milestone,
        },
        mocks: {
          $apollo: {
            mutate: mutationPromise(),
            queries: {
              currentAttribute: { loading: false },
              attributesList: { loading: false },
              ...queries,
            },
          },
        },
        stubs: {
          SidebarEditableItem,
          GlSearchBoxByType,
          GlDropdown,
        },
      }),
    );

    // We need to mock out `showDropdown` which
    // invokes `show` method of BDropdown used inside GlDropdown.
    jest.spyOn(wrapper.vm, 'showDropdown').mockImplementation();
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when not editing', () => {
    beforeEach(() => {
      createComponent({
        data: {
          currentAttribute: { id: 'id', title: 'title', webUrl: 'webUrl' },
        },
        stubs: {
          GlDropdown,
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
          currentAttribute: { loading: true },
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
          currentAttribute: { loading: false },
        },
      });

      expect(findEditableLoadingIcon().exists()).toBe(true);
      expect(findSelectedAttribute().text()).toBe('Some milestone title');
    });

    describe('when current attribute does not exist', () => {
      it('renders "None" as the selected attribute title', () => {
        createComponent();

        expect(findSelectedAttribute().text()).toBe('None');
      });
    });
  });

  describe('when a user can edit', () => {
    describe('when user is editing', () => {
      describe('when rendering the dropdown', () => {
        it('shows a loading spinner while fetching a list of attributes', async () => {
          createComponent({
            queries: {
              attributesList: { loading: true },
            },
          });

          await toggleDropdown();

          expect(findLoadingIconDropdown().exists()).toBe(true);
        });

        describe('GlDropdownItem with the right title and id', () => {
          const id = 'id';
          const title = 'title';

          beforeEach(async () => {
            createComponent({
              data: { attributesList: [{ id, title }], currentAttribute: { id, title } },
            });

            await toggleDropdown();
          });

          it('does not show a loading spinner', () => {
            expect(findLoadingIconDropdown().exists()).toBe(false);
          });

          it('renders title $title', () => {
            expect(findDropdownItemWithText(title).exists()).toBe(true);
          });

          it('checks the correct dropdown item', () => {
            expect(
              findAllDropdownItems()
                .filter((w) => w.props('isChecked') === true)
                .at(0)
                .text(),
            ).toBe(title);
          });
        });

        describe('when no data is assigned', () => {
          beforeEach(async () => {
            createComponent();

            await toggleDropdown();
          });

          it('finds GlDropdownItem with "No milestone"', () => {
            expect(findNoAttributeItem().text()).toBe('No milestone');
          });

          it('"No milestone" is checked', () => {
            expect(findNoAttributeItem().props('isChecked')).toBe(true);
          });

          it('does not render any dropdown item', () => {
            expect(findAttributeItems().exists()).toBe(false);
          });
        });

        describe('when clicking on dropdown item', () => {
          describe('when currentAttribute is equal to attribute id', () => {
            it('does not call setIssueAttribute mutation', async () => {
              createComponent({
                data: {
                  attributesList: [{ id: 'id', title: 'title' }],
                  currentAttribute: { id: 'id', title: 'title' },
                },
              });

              await toggleDropdown();

              findDropdownItemWithText('title').vm.$emit('click');

              expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(0);
            });
          });

          describe('when currentAttribute is not equal to attribute id', () => {
            describe('when error', () => {
              const bootstrapComponent = (mutationResp) => {
                createComponent({
                  data: {
                    attributesList: [
                      { id: '123', title: '123' },
                      { id: 'id', title: 'title' },
                    ],
                    currentAttribute: '123',
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

                  findDropdownItemWithText('title').vm.$emit('click');
                });

                it(`calls createFlash with "${expectedMsg}"`, async () => {
                  await wrapper.vm.$nextTick();
                  expect(createFlash).toHaveBeenCalledWith({
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

      describe('when a user is searching', () => {
        describe('when search result is not found', () => {
          it('renders "No milestone found"', async () => {
            createComponent();

            await toggleDropdown();

            findSearchBox().vm.$emit('input', 'non existing milestones');

            await wrapper.vm.$nextTick();

            expect(findDropdownText().text()).toBe('No milestone found');
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

        it('renders the dropdown on clicking edit', async () => {
          expect(findDropdown().isVisible()).toBe(true);
        });

        it('focuses on the input when dropdown is shown', async () => {
          expect(document.activeElement).toEqual(wrapper.findComponent(GlFormInput).element);
        });

        describe('when currentAttribute is not equal to attribute id', () => {
          describe('when update is successful', () => {
            beforeEach(() => {
              findDropdownItemWithText(mockMilestone2.title).vm.$emit('click');
            });

            it('calls setIssueAttribute mutation', () => {
              expect(milestoneMutationSpy).toHaveBeenCalledWith({
                iid: mockIssue.iid,
                attributeId: getIdFromGraphQLId(mockMilestone2.id),
                fullPath: mockIssue.projectPath,
              });
            });

            it('sets the value returned from the mutation to currentAttribute', async () => {
              expect(findSelectedAttribute().text()).toBe(mockMilestone2.title);
            });
          });
        });

        describe('milestones', () => {
          let projectMilestonesSpy;

          it('should call createFlash if milestones query fails', async () => {
            await createComponentWithApollo({
              projectMilestonesSpy: jest.fn().mockRejectedValue(error),
            });

            await clickEdit();

            expect(createFlash).toHaveBeenCalledWith({
              message: wrapper.vm.i18n.listFetchError,
              captureError: true,
              error: expect.any(Error),
            });
          });

          it('only fetches attributes when dropdown is opened', async () => {
            projectMilestonesSpy = jest.fn().mockResolvedValueOnce(emptyProjectMilestonesResponse);
            await createComponentWithApollo({ projectMilestonesSpy });

            expect(projectMilestonesSpy).not.toHaveBeenCalled();

            await clickEdit();

            expect(projectMilestonesSpy).toHaveBeenNthCalledWith(1, {
              fullPath: mockIssue.projectPath,
              sort: null,
              state: 'active',
              title: '',
            });
          });

          describe('when a user is searching', () => {
            const mockSearchTerm = 'foobar';

            beforeEach(async () => {
              projectMilestonesSpy = jest
                .fn()
                .mockResolvedValueOnce(emptyProjectMilestonesResponse);
              await createComponentWithApollo({ projectMilestonesSpy });

              await clickEdit();
            });

            it('sends a projectMilestones query with the entered search term "foo"', async () => {
              findSearchBox().vm.$emit('input', mockSearchTerm);
              await wrapper.vm.$nextTick();

              // Account for debouncing
              jest.runAllTimers();

              expect(projectMilestonesSpy).toHaveBeenNthCalledWith(2, {
                fullPath: mockIssue.projectPath,
                sort: null,
                state: 'active',
                title: mockSearchTerm,
              });
            });
          });
        });
      });

      describe('currentAttributes', () => {
        it('should call createFlash if currentAttributes query fails', async () => {
          await createComponentWithApollo({
            currentMilestoneSpy: jest.fn().mockRejectedValue(error),
          });

          expect(createFlash).toHaveBeenCalledWith({
            message: wrapper.vm.i18n.currentFetchError,
            captureError: true,
            error: expect.any(Error),
          });
        });
      });
    });
  });
});
